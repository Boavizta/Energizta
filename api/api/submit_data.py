import base64
import os
from datetime import datetime

from github import Github, GithubObject, InputGitAuthor, UnknownObjectException


def get_repo():
    g = Github(os.getenv("GITHUB_TOKEN"))
    repo = g.get_repo("Boavizta/Energizta")
    return repo


def init_branch(repo, branch_name):
    try:
        print(branch_name)
        branch = repo.get_git_ref(f"heads/{branch_name}")
    except UnknownObjectException:
        branch = repo.create_git_ref(
            f"refs/heads/{branch_name}", repo.get_branch("main").commit.sha
        )
    return branch


def get_content(repo, branch_name, path):
    try:
        content = repo.get_contents(path, f"refs/heads/{branch_name}")
    except UnknownObjectException:
        content = None
    return content


def commit_file(repo, branch_name, path, github_content, new_file, committer=None):
    date = datetime.now().strftime("%Y%m%d_%H%M%S")
    if github_content:
        if new_file.encode("ascii") != base64.b64decode(github_content.content):
            # TODO append new_file to content
            repo.update_file(
                path,
                f"Update file stress {date}",
                new_file,
                github_content.sha,
                branch=branch_name,
                committer=committer,
            )
    else:
        repo.create_file(
            path,
            f"Update file stress {date}",
            new_file,
            branch=branch_name,
            committer=committer,
        )


def init_pull_request(repo, batch_id, branch_name):
    title = f"Add data from stress test {batch_id}"
    pulls = repo.get_pulls(head=f"Boavitza:{branch_name}", base="main")
    if len(list(pulls)) == 0:
        repo.create_pull(title=title, body="", head=branch_name, base="main")


def register_stress_test(batch_id, file_content, username=None, email=None):
    repo = get_repo()
    branch_name = f"add_data_{batch_id}"
    path = "data/record.csv"
    init_branch(repo, branch_name)
    github_content = get_content(repo, branch_name, path)

    committer = GithubObject.NotSet
    if username and email:
        committer = InputGitAuthor(name=username, email=email)

    commit_file(
        repo, branch_name, path, github_content, file_content, committer=committer
    )

    init_pull_request(repo, batch_id, branch_name)
