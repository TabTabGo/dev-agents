#!/usr/bin/env python3
"""
Convert Claude Code agent definitions to GitHub Copilot instructions.

This script reads Claude agent markdown files and converts them to
Copilot-compatible instruction format.

Usage:
    python convert-claude-to-copilot.py <claude-agent.md> [output-file.md]
"""

import sys
import re
from pathlib import Path


def convert_agent_to_copilot(agent_content: str, agent_name: str) -> str:
    """Convert Claude agent format to Copilot instructions format."""

    # Extract sections from Claude agent
    sections = parse_claude_agent(agent_content)

    # Build Copilot instructions
    copilot_content = f"""# GitHub Copilot Instructions - {agent_name}

## Role

{sections.get('role', 'AI Development Assistant')}

## Responsibilities

{sections.get('responsibilities', '')}

## Code Standards

{sections.get('standards', '')}

## Templates and Patterns

{sections.get('templates', '')}

## Guidelines

When generating code:
1. Follow Clean Architecture principles
2. Use CQRS pattern (Commands modify, Queries read)
3. Write tests first (TDD approach)
4. Ensure >80% code coverage
5. Validate all inputs at Application layer
6. Use async/await with CancellationToken
7. Return DTOs from queries, not entities
8. Handle errors appropriately

## Common Patterns

{sections.get('patterns', '')}

---

*Generated from Claude agent: {agent_name}*
"""

    return copilot_content


def parse_claude_agent(content: str) -> dict:
    """Parse Claude agent markdown and extract key sections."""

    sections = {}

    # Extract first paragraph as role
    paragraphs = content.split('\n\n')
    if paragraphs:
        first_para = paragraphs[0].replace('#', '').strip()
        if first_para and not first_para.startswith('You are'):
            sections['role'] = first_para
        else:
            sections['role'] = paragraphs[1] if len(paragraphs) > 1 else ''

    # Extract responsibilities section
    resp_match = re.search(
        r'## Your Responsibilities\s+(.*?)(?=\n##|\Z)',
        content,
        re.DOTALL
    )
    if resp_match:
        sections['responsibilities'] = resp_match.group(1).strip()

    # Extract standards/constraints section
    std_match = re.search(
        r'##.*(?:Standards|Constraints|Quality)\s+(.*?)(?=\n##|\Z)',
        content,
        re.DOTALL
    )
    if std_match:
        sections['standards'] = std_match.group(1).strip()

    # Extract code templates
    template_match = re.search(
        r'##.*(?:Template|Pattern|Example)\s+(.*?)(?=\n##|\Z)',
        content,
        re.DOTALL
    )
    if template_match:
        sections['templates'] = template_match.group(1).strip()

    # Extract patterns section
    pattern_match = re.search(
        r'## Common Patterns\s+(.*?)(?=\n##|\Z)',
        content,
        re.DOTALL
    )
    if pattern_match:
        sections['patterns'] = pattern_match.group(1).strip()

    return sections


def main():
    if len(sys.argv) < 2:
        print("Error: Claude agent file required")
        print(f"Usage: {sys.argv[0]} <claude-agent.md> [output-file.md]")
        sys.exit(1)

    input_file = Path(sys.argv[1])

    if not input_file.exists():
        print(f"Error: File not found: {input_file}")
        sys.exit(1)

    # Read Claude agent file
    agent_content = input_file.read_text()
    agent_name = input_file.stem.replace('-', ' ').title()

    # Convert to Copilot format
    copilot_content = convert_agent_to_copilot(agent_content, agent_name)

    # Determine output file
    if len(sys.argv) >= 3:
        output_file = Path(sys.argv[2])
    else:
        output_file = Path(f"copilot-{input_file.stem}.md")

    # Write output
    output_file.write_text(copilot_content)

    print(f"✓ Converted {input_file.name} to {output_file.name}")
    print(f"  Agent: {agent_name}")
    print(f"  Output: {output_file}")


if __name__ == "__main__":
    main()
