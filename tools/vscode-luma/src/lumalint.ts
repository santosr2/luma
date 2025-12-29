/**
 * Lumalint integration for VSCode
 */

import * as vscode from 'vscode';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

export interface LintResult {
    file: string;
    line: number;
    column: number;
    severity: 'error' | 'warning' | 'info';
    message: string;
    rule?: string;
}

/**
 * Run lumalint on a document
 */
export async function lintDocument(document: vscode.TextDocument): Promise<vscode.Diagnostic[]> {
    const config = vscode.workspace.getConfiguration('luma.lint');
    const lumalintPath = config.get<string>('lumalintPath', 'lumalint');
    const enabled = config.get<boolean>('enabled', true);

    if (!enabled) {
        return [];
    }

    try {
        // Try running lumalint
        const { stdout, stderr } = await execAsync(
            `"${lumalintPath}" --format=json "${document.fileName}"`,
            { timeout: 5000 }
        );

        if (stderr) {
            console.error('Lumalint stderr:', stderr);
        }

        // Parse JSON output
        try {
            const results: LintResult[] = JSON.parse(stdout);
            return results.map(resultToDiagnostic);
        } catch (parseError) {
            // If JSON parsing fails, try parsing plain text output
            return parsePlainTextOutput(stdout, document);
        }
    } catch (error: any) {
        // Lumalint not found or other error
        if (error.code === 'ENOENT' || error.message.includes('command not found')) {
            // Silently fall back to basic linting
            return basicLint(document);
        }

        // Show error to user
        vscode.window.showErrorMessage(`Lumalint error: ${error.message}`);
        return basicLint(document);
    }
}

/**
 * Convert lumalint result to VSCode diagnostic
 */
function resultToDiagnostic(result: LintResult): vscode.Diagnostic {
    const line = Math.max(0, result.line - 1); // Convert 1-based to 0-based
    const column = Math.max(0, result.column - 1);
    
    const range = new vscode.Range(
        line,
        column,
        line,
        column + 10 // Approximate length
    );

    const severity = 
        result.severity === 'error' ? vscode.DiagnosticSeverity.Error :
        result.severity === 'warning' ? vscode.DiagnosticSeverity.Warning :
        vscode.DiagnosticSeverity.Information;

    const diagnostic = new vscode.Diagnostic(range, result.message, severity);
    
    if (result.rule) {
        diagnostic.code = result.rule;
    }

    diagnostic.source = 'lumalint';
    return diagnostic;
}

/**
 * Parse plain text lumalint output
 */
function parsePlainTextOutput(output: string, document: vscode.TextDocument): vscode.Diagnostic[] {
    const diagnostics: vscode.Diagnostic[] = [];
    const lines = output.split('\n');

    for (const line of lines) {
        // Match format: "file.luma:10:5: error: message"
        const match = line.match(/^.*?:(\d+):(\d+):\s*(error|warning|info):\s*(.+)$/);
        if (match) {
            const lineNum = parseInt(match[1], 10) - 1;
            const colNum = parseInt(match[2], 10) - 1;
            const severity = match[3];
            const message = match[4];

            const range = new vscode.Range(lineNum, colNum, lineNum, colNum + 10);
            const diagSeverity = 
                severity === 'error' ? vscode.DiagnosticSeverity.Error :
                severity === 'warning' ? vscode.DiagnosticSeverity.Warning :
                vscode.DiagnosticSeverity.Information;

            const diagnostic = new vscode.Diagnostic(range, message, diagSeverity);
            diagnostic.source = 'lumalint';
            diagnostics.push(diagnostic);
        }
    }

    return diagnostics;
}

/**
 * Basic linting fallback when lumalint is not available
 */
function basicLint(document: vscode.TextDocument): vscode.Diagnostic[] {
    const diagnostics: vscode.Diagnostic[] = [];
    const text = document.getText();
    const lines = text.split('\n');

    // Check for unmatched directives
    const directiveStack: Array<{ name: string; line: number; column: number }> = [];

    lines.forEach((line, lineIndex) => {
        // Check for opening directives
        const openMatch = line.match(/@(if|for|macro|block|call|autoescape|filter|extends|raw|comment|with)\b/);
        if (openMatch) {
            directiveStack.push({ 
                name: openMatch[1], 
                line: lineIndex,
                column: openMatch.index || 0
            });
        }

        // Check for @end
        const endMatch = line.match(/@end\b/);
        if (endMatch) {
            if (directiveStack.length === 0) {
                diagnostics.push(
                    new vscode.Diagnostic(
                        new vscode.Range(lineIndex, endMatch.index || 0, lineIndex, (endMatch.index || 0) + 4),
                        'Unexpected @end without matching opening directive',
                        vscode.DiagnosticSeverity.Error
                    )
                );
            } else {
                directiveStack.pop();
            }
        }

        // Check for undefined filters (simple heuristic)
        const knownFilters = [
            'upper', 'lower', 'capitalize', 'title', 'trim', 'length', 'default',
            'join', 'sort', 'reverse', 'first', 'last', 'sum', 'safe', 'abs',
            'round', 'int', 'float', 'list', 'dict', 'string', 'escape', 'safe'
        ];

        const filterMatches = line.matchAll(/\|\s*([a-zA-Z_][a-zA-Z0-9_]*)/g);
        for (const match of filterMatches) {
            const filterName = match[1];
            if (!knownFilters.includes(filterName)) {
                diagnostics.push(
                    new vscode.Diagnostic(
                        new vscode.Range(
                            lineIndex,
                            (match.index || 0) + 1, // Skip the |
                            lineIndex,
                            (match.index || 0) + 1 + filterName.length
                        ),
                        `Unknown filter '${filterName}'`,
                        vscode.DiagnosticSeverity.Warning
                    )
                );
            }
        }

        // Check for potential syntax errors
        // Unmatched ${
        const openBraceMatches = [...line.matchAll(/\$\{/g)];
        const closeBraceMatches = [...line.matchAll(/\}/g)];
        if (openBraceMatches.length > closeBraceMatches.length) {
            const lastMatch = openBraceMatches[openBraceMatches.length - 1];
            diagnostics.push(
                new vscode.Diagnostic(
                    new vscode.Range(
                        lineIndex,
                        lastMatch.index || 0,
                        lineIndex,
                        (lastMatch.index || 0) + 2
                    ),
                    'Unclosed ${ expression',
                    vscode.DiagnosticSeverity.Error
                )
            );
        }
    });

    // Check for unclosed directives
    directiveStack.forEach((directive) => {
        diagnostics.push(
            new vscode.Diagnostic(
                new vscode.Range(directive.line, directive.column, directive.line, directive.column + directive.name.length + 1),
                `Unclosed @${directive.name} directive`,
                vscode.DiagnosticSeverity.Error
            )
        );
    });

    return diagnostics;
}

/**
 * Check if lumalint is available
 */
export async function checkLumalintAvailable(): Promise<boolean> {
    const config = vscode.workspace.getConfiguration('luma.lint');
    const lumalintPath = config.get<string>('lumalintPath', 'lumalint');

    try {
        await execAsync(`"${lumalintPath}" --version`, { timeout: 2000 });
        return true;
    } catch {
        return false;
    }
}

/**
 * Get lumalint version
 */
export async function getLumalintVersion(): Promise<string | null> {
    const config = vscode.workspace.getConfiguration('luma.lint');
    const lumalintPath = config.get<string>('lumalintPath', 'lumalint');

    try {
        const { stdout } = await execAsync(`"${lumalintPath}" --version`, { timeout: 2000 });
        return stdout.trim();
    } catch {
        return null;
    }
}

