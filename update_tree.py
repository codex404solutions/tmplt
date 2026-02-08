import os
import subprocess
import re


def get_repo_name():
    try:
        url = (
            subprocess.check_output(["git", "config", "--get", "remote.origin.url"])
            .decode()
            .strip()
        )

        return url.rstrip(".git").split("/")[-1]
    except Exception:
        return "project-name"


def format_project_name(repo_name: str) -> str:
    # Convert camelCase to words
    name = re.sub(r"([a-z])([A-Z])", r"\1 \2", repo_name)

    # Replace _ and - with space
    name = name.replace("_", " ").replace("-", " ")

    # Capitalize each word
    return " ".join(word.capitalize() for word in name.split())


def generate_tree(path=".", prefix=""):
    tree = []
    ignore = {".git", ".venv", "__pycache__", "build", "dist"}

    items = sorted(
        i for i in os.listdir(path) if i not in ignore and not i.startswith(".")
    )

    for index, name in enumerate(items):
        full = os.path.join(path, name)
        connector = "└── " if index == len(items) - 1 else "├── "
        tree.append(f"{prefix}{connector}{name}")

        if os.path.isdir(full):
            extension = "    " if index == len(items) - 1 else "│   "
            tree.extend(generate_tree(full, prefix + extension))

    return tree


def update_readme():
    repo_name = get_repo_name()
    project_name = format_project_name(repo_name)
    tree = "\n".join(generate_tree())

    with open("README.md", "r", encoding="utf-8") as f:
        content = f.read()

    # Replace placeholders
    content = content.replace("{{REPO_NAME}}", repo_name)
    content = content.replace("{{PROJECT_NAME}}", project_name)

    start = "<!-- TREE_START -->"
    end = "<!-- TREE_END -->"
    block = f"{start}\n```\n{tree}\n```\n{end}"

    if start in content and end in content:
        content = content.split(start)[0] + block + content.split(end)[1]
    else:
        content += "\n\n" + block

    with open("README.md", "w", encoding="utf-8") as f:
        f.write(content)


if __name__ == "__main__":
    update_readme()
