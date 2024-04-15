#!/usr/bin/bash


# Take user input - Organization name
read -p "Enter your org name: " org

echo "[+] Script started to execute ..."
# make Main directory to save all output
mkdir -p $org

# fetch all repositories in organization
gh repo list $org | awk -F ' ' '{print $1}'| awk -F '/' '{print $2}' > $org/repositories.txt


# fetch branch protection rules for all individual branches
while IFS= read -r repo;do
        # make directories for all repositories
        mkdir -p $org/$repo

        # fetch branch protection rules for individual repository
        gh api repos/$org/$repo/branches/main/protection | tee -a $org/branch_protections.json $org/$repo/branch_prot_rule.json;

        # fetch CODEOWNER for every individual repository
        gh grep ^ --owner $org --repo $repo --include=CODEOWNERS | tee -a $org/codeowners.txt $org/$repo/codeowner.txt;

        # fetach SECURITY.md file for every individual repository
        gh grep ^ --owner $org --repo $repo --include=SECURITY.md | tee -a $org/security_md.txt $org/$repo/security_md.txt;

        # fetch and store all branches names for every individial repositories
        gh api repos/$org/$repo/branches -q '.[].name' > $org/$repo/branches;

        # check for stale branch
        while IFS= read -r branch;do
                gh api repos/$org/$repo/branches/$branch | tee -a $org/$repo/$branch;
        done < $org/$repo/branches;

        # fetch workflow files
        gh api /repos/$org/$repo/actions/workflows  -q '.workflows[].id' | tee -a $org/$repo/workflows;
        while IFS= read -r id;do
                gh workflow view $id -y -R $org/$repo | tee -a $org/$repo/workflow_$id;
        done < $org/$repo/workflows;

done < $org/repositories.txt

echo "[+] Script executed successfully!"

# creating zip file
zip -r accorianXengine_GitReview.zip $org
