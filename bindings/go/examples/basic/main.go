package main

import (
	"fmt"
	"log"

	"github.com/santosr2/luma/bindings/go"
)

func main() {
	// Example 1: Simple rendering
	fmt.Println("=== Example 1: Simple Variable ===")
	result, err := luma.Render("Hello, $name!", map[string]interface{}{
		"name": "World",
	})
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println(result)

	// Example 2: Conditional rendering
	fmt.Println("\n=== Example 2: Conditional ===")
	result, err = luma.Render(`@if show
Welcome!
@else
Goodbye!
@end`, map[string]interface{}{
		"show": true,
	})
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println(result)

	// Example 3: Loop rendering
	fmt.Println("\n=== Example 3: Loop ===")
	result, err = luma.Render(`@for item in items
- $item
@end`, map[string]interface{}{
		"items": []interface{}{"apple", "banana", "cherry"},
	})
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println(result)

	// Example 4: Compiled template (reusable)
	fmt.Println("\n=== Example 4: Compiled Template ===")
	tmpl, err := luma.Compile("Hello, $name!")
	if err != nil {
		log.Fatal(err)
	}

	for _, name := range []string{"Alice", "Bob", "Charlie"} {
		result, err := tmpl.Execute(map[string]interface{}{
			"name": name,
		})
		if err != nil {
			log.Fatal(err)
		}
		fmt.Println(result)
	}

	// Example 5: Filters
	fmt.Println("\n=== Example 5: Filters ===")
	result, err = luma.Render("$name | upper", map[string]interface{}{
		"name": "hello",
	})
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println(result)

	// Example 6: Jinja2 syntax (also supported)
	fmt.Println("\n=== Example 6: Jinja2 Syntax ===")
	result, err = luma.Render("Hello, {{ name }}!", map[string]interface{}{
		"name": "Jinja",
	})
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println(result)
}
