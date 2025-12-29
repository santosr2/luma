import * as vscode from 'vscode';
import { lintDocument, checkLumalintAvailable, getLumalintVersion } from './lumalint';

export function activate(context: vscode.ExtensionContext) {
    console.log('Luma extension activated');

    // Check if lumalint is available and show status
    checkLumalintStatus();

    // Register commands
    const renderPreview = vscode.commands.registerCommand('luma.renderPreview', () => {
        const editor = vscode.window.activeTextEditor;
        if (!editor) {
            vscode.window.showErrorMessage('No active editor');
            return;
        }

        const document = editor.document;
        const content = document.getText();

        // Create webview panel for preview
        const panel = vscode.window.createWebviewPanel(
            'lumaPreview',
            'Luma Preview',
            vscode.ViewColumn.Beside,
            {
                enableScripts: true,
            }
        );

        panel.webview.html = getPreviewHtml(content);
    });

    const lintCurrentFile = vscode.commands.registerCommand('luma.lintCurrentFile', async () => {
        const editor = vscode.window.activeTextEditor;
        if (!editor) {
            vscode.window.showErrorMessage('No active editor');
            return;
        }

        vscode.window.showInformationMessage('Linting Luma template...');

        // Use real lumalint integration
        const diagnostics = await lintDocument(editor.document);

        // Show results
        if (diagnostics.length === 0) {
            vscode.window.showInformationMessage('No issues found ✓');
        } else {
            vscode.window.showWarningMessage(`Found ${diagnostics.length} issue(s)`);
        }
    });

    const formatDocument = vscode.commands.registerCommand('luma.formatDocument', () => {
        const editor = vscode.window.activeTextEditor;
        if (!editor) {
            vscode.window.showErrorMessage('No active editor');
            return;
        }

        vscode.window.showInformationMessage('Formatting Luma template...');

        // Format using the registered formatter
        vscode.commands.executeCommand('editor.action.formatDocument');
    });

    // Register document formatting provider
    const lumaFormatter = vscode.languages.registerDocumentFormattingEditProvider('luma', {
        provideDocumentFormattingEdits(document: vscode.TextDocument): vscode.TextEdit[] {
            return formatLumaDocument(document);
        },
    });

    // Register completion provider
    const lumaCompletion = vscode.languages.registerCompletionItemProvider(
        ['luma', 'jinja-luma'],
        {
            provideCompletionItems(
                document: vscode.TextDocument,
                position: vscode.Position
            ): vscode.CompletionItem[] {
                return getLumaCompletions(document, position);
            },
        },
        '@', '$', '{', '|'
    );

    // Register hover provider
    const lumaHover = vscode.languages.registerHoverProvider(['luma', 'jinja-luma'], {
        provideHover(
            document: vscode.TextDocument,
            position: vscode.Position
        ): vscode.Hover | undefined {
            return getLumaHover(document, position);
        },
    });

    // Register diagnostic provider (linting)
    const diagnosticCollection = vscode.languages.createDiagnosticCollection('luma');
    context.subscriptions.push(diagnosticCollection);

    // Lint on save
    const onSaveDisposable = vscode.workspace.onDidSaveTextDocument(async (document) => {
        if (document.languageId === 'luma' || document.languageId === 'jinja-luma') {
            const config = vscode.workspace.getConfiguration('luma.lint');
            if (config.get('enabled') && config.get('onSave')) {
                const diagnostics = await lintDocument(document);
                diagnosticCollection.set(document.uri, diagnostics);
            }
        }
    });

    // Lint on type (if enabled)
    const onChangeDisposable = vscode.workspace.onDidChangeTextDocument(async (event) => {
        const config = vscode.workspace.getConfiguration('luma.lint');
        if (
            config.get('enabled') &&
            config.get('onType') &&
            (event.document.languageId === 'luma' || event.document.languageId === 'jinja-luma')
        ) {
            const diagnostics = await lintDocument(event.document);
            diagnosticCollection.set(event.document.uri, diagnostics);
        }
    });

    context.subscriptions.push(
        renderPreview,
        lintCurrentFile,
        formatDocument,
        lumaFormatter,
        lumaCompletion,
        lumaHover,
        onSaveDisposable,
        onChangeDisposable
    );
}

export function deactivate() {
    console.log('Luma extension deactivated');
}

function getPreviewHtml(content: string): string {
    return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Luma Preview</title>
    <style>
        body {
            font-family: monospace;
            padding: 20px;
            background: #1e1e1e;
            color: #d4d4d4;
        }
        pre {
            background: #252526;
            padding: 15px;
            border-radius: 5px;
            overflow-x: auto;
        }
        .info {
            background: #1e3a8a;
            color: #fff;
            padding: 10px;
            border-radius: 5px;
            margin-bottom: 15px;
        }
    </style>
</head>
<body>
    <div class="info">
        <strong>Luma Preview</strong><br>
        To render this template, provide context data and use the Luma CLI or API.
    </div>
    <pre>${escapeHtml(content)}</pre>
</body>
</html>`;
}

function escapeHtml(text: string): string {
    return text
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;');
}

async function checkLumalintStatus(): Promise<void> {
    const available = await checkLumalintAvailable();
    if (available) {
        const version = await getLumalintVersion();
        console.log(`Lumalint available: ${version}`);
    } else {
        console.log('Lumalint not found, using basic linting');
        vscode.window.showInformationMessage(
            'Lumalint not found. Install it for advanced linting features: luarocks install lumalint',
            'Learn More'
        ).then(selection => {
            if (selection === 'Learn More') {
                vscode.env.openExternal(vscode.Uri.parse('https://github.com/santosr2/luma/tree/main/tools/lumalint'));
            }
        });
    }
}

function formatLumaDocument(document: vscode.TextDocument): vscode.TextEdit[] {
    const edits: vscode.TextEdit[] = [];
    const config = vscode.workspace.getConfiguration('luma.format');
    const indentSize = config.get<number>('indentSize', 2);

    // Simple formatting: maintain proper indentation
    const lines = document.getText().split('\n');
    let indentLevel = 0;
    const formattedLines: string[] = [];

    lines.forEach((line) => {
        const trimmed = line.trim();

        // Decrease indent for @end, @else, @elif
        if (trimmed.match(/^@(end|else|elif)\b/)) {
            indentLevel = Math.max(0, indentLevel - 1);
        }

        // Add indented line
        const indent = ' '.repeat(indentLevel * indentSize);
        formattedLines.push(indent + trimmed);

        // Increase indent after opening directives
        if (
            trimmed.match(/^@(if|for|macro|block|call|autoescape|filter|extends|raw)\b/) &&
            !trimmed.includes('@end')
        ) {
            indentLevel++;
        }

        // Decrease indent after @end
        if (trimmed.match(/^@end\b/)) {
            indentLevel = Math.max(0, indentLevel - 1);
        }
    });

    // Create edit to replace entire document
    const fullRange = new vscode.Range(
        document.positionAt(0),
        document.positionAt(document.getText().length)
    );
    edits.push(vscode.TextEdit.replace(fullRange, formattedLines.join('\n')));

    return edits;
}

function getLumaCompletions(
    document: vscode.TextDocument,
    position: vscode.Position
): vscode.CompletionItem[] {
    const completions: vscode.CompletionItem[] = [];

    // Directive completions
    const directives = [
        'if',
        'elif',
        'else',
        'for',
        'macro',
        'call',
        'let',
        'block',
        'import',
        'from',
        'extends',
        'include',
        'autoescape',
        'filter',
        'raw',
        'comment',
        'do',
        'end',
        'break',
        'continue',
    ];

    directives.forEach((directive) => {
        const item = new vscode.CompletionItem(`@${directive}`, vscode.CompletionItemKind.Keyword);
        item.insertText = new vscode.SnippetString(`@${directive} `);
        item.documentation = `Luma ${directive} directive`;
        completions.push(item);
    });

    // Filter completions
    const filters = [
        'upper',
        'lower',
        'capitalize',
        'title',
        'trim',
        'length',
        'default',
        'join',
        'sort',
        'reverse',
        'first',
        'last',
        'sum',
        'safe',
    ];

    filters.forEach((filter) => {
        const item = new vscode.CompletionItem(filter, vscode.CompletionItemKind.Function);
        item.insertText = filter;
        item.documentation = `Luma ${filter} filter`;
        completions.push(item);
    });

    return completions;
}

function getLumaHover(
    document: vscode.TextDocument,
    position: vscode.Position
): vscode.Hover | undefined {
    const range = document.getWordRangeAtPosition(position);
    if (!range) {
        return undefined;
    }

    const word = document.getText(range);

    // Provide hover documentation for directives
    const directiveDocs: Record<string, string> = {
        if: 'Conditional statement. Use with @elif, @else, and @end.',
        for: 'Loop over items. Provides loop variable with index, first, last, etc.',
        macro: 'Define a reusable macro with parameters.',
        let: 'Define a variable.',
        block: 'Define a block for template inheritance.',
        extends: 'Inherit from a base template.',
        import: 'Import another template.',
        autoescape: 'Control HTML escaping.',
        filter: 'Apply a filter to a block of content.',
    };

    if (directiveDocs[word]) {
        return new vscode.Hover(
            new vscode.MarkdownString(`**@${word}**\n\n${directiveDocs[word]}`)
        );
    }

    // Provide hover documentation for filters
    const filterDocs: Record<string, string> = {
        upper: 'Convert string to uppercase',
        lower: 'Convert string to lowercase',
        capitalize: 'Capitalize first letter',
        trim: 'Remove leading and trailing whitespace',
        default: 'Provide default value if variable is undefined',
        join: 'Join list items into a string',
        safe: 'Mark string as safe (no HTML escaping)',
    };

    if (filterDocs[word]) {
        return new vscode.Hover(new vscode.MarkdownString(`**${word}** filter\n\n${filterDocs[word]}`));
    }

    return undefined;
}
