import Foundation

struct ProjectTemplate: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let description: String
    let prompt: String?

    static let templates: [ProjectTemplate] = [
        ProjectTemplate(
            name: "Web App",
            icon: "globe",
            description: "Full-stack web app",
            prompt: "Build a modern web application. Ask me what I want to build, then scaffold it with a clean UI, API routes, and a database. Use best practices for the stack I choose. Run the dev server on port 8080."
        ),
        ProjectTemplate(
            name: "API",
            icon: "server.rack",
            description: "REST or GraphQL API",
            prompt: "Build a production-ready API. Ask me what endpoints I need, then scaffold it with proper routing, validation, error handling, and a database. Include a health check endpoint and basic auth. Run on port 8080."
        ),
        ProjectTemplate(
            name: "Script",
            icon: "terminal",
            description: "Automation or CLI tool",
            prompt: "Build a CLI tool or automation script. Ask me what I want to automate, then build it with proper argument parsing, error handling, and helpful output. Make it installable and well-documented."
        ),
        ProjectTemplate(
            name: "Custom",
            icon: "plus",
            description: "Describe anything",
            prompt: nil
        )
    ]
}
