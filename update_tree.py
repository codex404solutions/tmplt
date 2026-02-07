import os
import subprocess


def get_repo_name():
    try:
        url = (
            subprocess.check_output(
                ["git", "config", "--get", "remote.origin.url"],
                stderr=subprocess.DEVNULL,
            )
            .decode()
            .strip()
        )

        repo = url.split("/")[-1].replace(".git", "")
        return repo
    except Exception:
        return "Project Name"


def generate_tree(path=".", prefix=""):
    tree = []
    files = sorted(os.listdir(path))

    filtered = [
        f
        for f in files
        if not f.startswith(".") and f not in ["__pycache__", "build", "dist", ".git"]
    ]

    for index, name in enumerate(filtered):
        full_path = os.path.join(path, name)
        connector = "└── " if index == len(filtered) - 1 else "├── "
        tree.append(f"{prefix}{connector}{name}")

        if os.path.isdir(full_path):
            extension = "    " if index == len(filtered) - 1 else "│   "
            tree.extend(generate_tree(full_path, prefix + extension))

    return tree


def update_readme(readme="README.md"):
    repo_name = get_repo_name()
    tree = "\n".join(generate_tree())

    with open(readme, "r", encoding="utf-8") as f:
        content = f.read()

    # Replace repo name placeholder
    content = content.replace("{{REPO_NAME}}", repo_name)

    start = "<!-- TREE_START -->"
    end = "<!-- TREE_END -->"
    new_section = f"{start}\n```\n{tree}\n```\n{end}"

    if start in content and end in content:
        content = content.split(start)[0] + new_section + content.split(end)[1]
    else:
        content += f"\n\n{new_section}"

    with open(readme, "w", encoding="utf-8") as f:
        f.write(content)


if __name__ == "__main__":
    update_readme()
