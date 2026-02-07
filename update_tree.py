import os
import subprocess


def get_repo_name():
    try:
        url = (
            subprocess.check_output(["git", "config", "--get", "remote.origin.url"])
            .decode()
            .strip()
        )

        if not url:
            return "Project Name"

        return url.rstrip(".git").split("/")[-1]

    except Exception as e:
        print("Repo detection failed:", e)
        return "Project Name"


def generate_tree(path=".", prefix=""):
    tree = []
    items = sorted(os.listdir(path))

    ignore = {".git", ".venv", "__pycache__", "build", "dist"}

    items = [i for i in items if i not in ignore and not i.startswith(".")]

    for index, name in enumerate(items):
        full = os.path.join(path, name)
        connector = "└── " if index == len(items) - 1 else "├── "
        tree.append(f"{prefix}{connector}{name}")

        if os.path.isdir(full):
            extension = "    " if index == len(items) - 1 else "│   "
            tree.extend(generate_tree(full, prefix + extension))

    return tree


def update_readme():
    repo = get_repo_name()
    tree = "\n".join(generate_tree())

    with open("README.md", "r", encoding="utf-8") as f:
        content = f.read()

    content = content.replace("{{REPO_NAME}}", repo)

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
