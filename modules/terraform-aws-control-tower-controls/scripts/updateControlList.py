import re
import json
import requests
from bs4 import BeautifulSoup

file_path = "../controlsList.tf"

def getControlsFromAWS():
    url = "https://docs.aws.amazon.com/controltower/latest/controlreference/all-global-identifiers.html"
    response = requests.get(url)
    soup = BeautifulSoup(response.text, "html.parser")

    AWSControls = {}
    for pre_block in soup.find_all("pre", class_="programlisting"):
        code_block = pre_block.find("code")
        if code_block:
            try:
                control_data = json.loads(code_block.text.strip())
                AWSControls.update(control_data)
            except json.JSONDecodeError:
                continue

    return AWSControls

def getControlsFromFile():
    pattern = r"all_controls\s*=\s*{\s*([^}]+)}"
    controls = {}

    try:
        with open(file_path, "r") as file:
            file_content = file.read()
            match = re.search(pattern, file_content, re.DOTALL)
            if match:
                controls_block = match.group(1)
                lines = controls_block.splitlines()
                for line in lines:
                    kv_match = re.match(r'"([^"]+)"\s*:\s*"([^"]+)"', line.strip())
                    if kv_match:
                        control_name = kv_match.group(1)
                        control_id = kv_match.group(2)
                        controls[control_name] = control_id

        return controls

    except FileNotFoundError:
        print(f"File not found: {file_path}")
    except Exception as e:
        print(f"An error occurred: {e}")

def updateControlsList(AWSControls):
    try:
        with open(file_path, "r") as file:
            file_content = file.read()
        pattern = r"(all_controls\s*=\s*{\s*).*?(\s*})"
        replacement = "all_controls = {\n"

        for control_name, control_id in AWSControls.items():
            replacement += f'      "{control_name}" : "{control_id}",\n'
        replacement += "    }"

        updated_content = re.sub(pattern, replacement, file_content, flags=re.DOTALL)

        with open(file_path, "w") as file:
            file.write(updated_content)

        print(f"all_controls successfully updated in {file_path}.")
    except Exception as e:
        print(f"An error occurred while updating all_controls: {e}")


def compareControls(AWSControls, localControls):
    missingControls = {}
    for aws_control, aws_id in AWSControls.items():
        if aws_control not in localControls:
            missingControls[aws_control] = aws_id

    return missingControls

AWSControls = getControlsFromAWS()
localControls = getControlsFromFile()
missingControls = compareControls(AWSControls, localControls)

updateControlsList(AWSControls)

if len(missingControls) > 0:
    print("New controls added in local file:")
    print(json.dumps(missingControls, indent=4))
else:
    print("controlsList.tf is not missing any new controls")
