# Technical Documentation: A Cross-Disciplinary Approach

## Introduction to Technical Documentation

### Definition and Roles

Technical documentation is an essential component of a project's lifecycle. It allows:

- Knowledge transfer.
- Easier system maintenance and evolution.
- Improved user and developer experience.

### Types of Documentation

- User Documentation
- API Documentation
- Architecture Documentation
- Reference Documentation and Practical Guides

## Structuring Knowledge

### Structuring Methods

#### **Zettelkasten**

A dynamic approach to knowledge management:

- Interconnected notes
- Facilitates research and critical thinking

#### **Diátaxis**

A structure based on user needs:

- Tutorials
- How-To Guides
- References
- Explanations

## Documentation Types and Evolution

### ADR (Architectural Decision Records)

- Documenting architectural decisions
- Transparency and tracking project evolution

### Tech Radar

- Tracking technologies in use and under evaluation
- Aiding in technical decision-making

### EventStorming

- Collaborative modeling of business processes
- Identifying critical points in a system

## Best Practices for Writing Documentation

### Clarity and Structure

- Using simple and precise language
- Organizing content into coherent sections and subsections

### Consistency and Uniformity

- Adhering to style guides
- Using automated validation tools: [Vale](https://github.com/errata-ai/vale), [Doc Detective](https://doc-detective.com/docs/category/configuration)

## Accessibility in Documentation

### Why Make Documentation Accessible?

- Inclusion for all users
- Compliance with standards (e.g., WCAG)

### Tools and Best Practices

- [mdBook](https://github.com/rust-lang/mdBook): Generating accessible digital documentation
- [Vale](https://github.com/errata-ai/vale): Verifying accessibility standards
- [Doc detective](https://doc-detective.com/docs/get-started/intro): Verifying accessibility standards

## Automating Documentation

### Automating Repository Linting

- Checking syntax and style
- [VHS](https://github.com/charmbracelet/vhs): Capturing terminal sessions and creating interactive tutorials
- [Vale](https://github.com/errata-ai/vale): Automatic style checking

______________________________________________________________________

## Automatic Documentation Generation

### Generating Documentation from Source Code

- [rustdoc](https://doc.rust-lang.org/rustdoc/write-documentation/documentation-tests.html): Automatically extracting documentation from code comments
- [mdBook cmd-run](https://github.com/rust-lang/mdBook): Running commands within documentation
- [VHS](https://github.com/charmbracelet/vhs): Interactive documentation with execution recordings

______________________________________________________________________

## Collaboration and Version Control

### Versioning Documentation

- Using Git and GitHub
- Review process with pull requests
- [ADR](https://adr.github.io/) for decision tracking

______________________________________________________________________

## Tools and Dedicated Platforms

### Overview of Collaborative Tools

- [mdBook](https://github.com/rust-lang/mdBook): Generating digital books
- [EventStorming](https://www.eventstorming.com/): Collaborative documentation modeling
- [Tech Radar](https://github.com/zalando/tech-radar): Tracking technology choices

______________________________________________________________________

## LLM and AI for Documentation

### AI-Assisted Writing and Automatic Generation

- [AIChat](https://github.com/sigoden/aichat): Command-line AI assistant
- [Mermaid Chart GPT](https://docs.mermaidchart.com/plugins/mermaid-chart-gpt): Automatically generating diagrams

______________________________________________________________________
