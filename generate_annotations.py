# lje-util
# Generates the annotations for LJE by parsing the JSON files

# Type-checking in python is very irritating
# type: ignore

import os
import json
import typing
import urllib.request
import zipfile
import shutil

JSONInstance = typing.Union[dict[str, "JSONInstance"], list["JSONInstance"], str, int, float, bool]

namespaces = []
output = []

pathout = "lje-git-repo-lje-util"
pathin = pathout + "-zip"
urllib.request.urlretrieve("https://github.com/lj-expand/lj-expand/archive/refs/heads/expansion.zip", pathin)
with zipfile.ZipFile(pathin, "r") as zip:
    zip.extractall(pathout)

os.remove(pathin)

path = pathout + "\\lj-expand-expansion\\docs\\api"

#path = input("Path to 'lj-expand/docs/api':\t")

def getformatteddescription(description):
    if (not (type(description) is list)):
        description = description.split("\n")

    descriptionoutput = []
    for line in description:
        descriptionoutput.append("--- " + line)
    return "\n".join(descriptionoutput)

def parse(data: dict[str, JSONInstance]):
    if (not ("namespace" in data)):
        return

    namespace = data["namespace"]
    constants = data["constants"] if ("constants" in data) else []
    functions = data["functions"] if ("functions" in data) else []

    isbase = namespace == "base"

    if (isbase):
        fprefix = "lje."
        cprefix = ""
    else:
        fprefix = "lje." + namespace + "."
        cprefix = fprefix
        namespaces.append(f"{getformatteddescription(data['description'])}\nlje.{namespace} = {{}}")
    
    for const in constants:
        if (isbase and not const['name'].startswith("lje.")):
            continue # Don't add polyfills and stuff like that

        descriptionstring = getformatteddescription(const['description'])

        line = []

        line.append(descriptionstring)
        line.append(f"--- @type {const['type']}")
        line.append(f"{cprefix}{const['name']} = nil")
        output.append("\n".join(line))
    
    for function in functions:
        returns = []
        for ret in function['returns']:
            string: str = ret['type']
            if (string.find("...") != -1):
                string = "..."
            returns.append(string)

        if (len(returns) == 0):
            returns.append("nil")

        descriptionstring = getformatteddescription(function['description'])

        line = []

        #line.append(f"--- {descriptionstring}")
        #line.append(f"--- @type fun({', '.join(params)}): {', '.join(returns)}")
        #line.append(f"{fprefix}{function['name']} = nil")

        line.append(descriptionstring)

        params = []
        for param in function["params"]:
            line.append(f"--- @param {param['name']} {param['type']} {param['description']}")
            params.append(param['name'])
        
        line.append("--- @return " + ", ".join(returns))
        line.append(f"function {fprefix}{function['name']}({', '.join(params)}) end --- @diagnostic disable-line")
        output.append("\n".join(line))

directory = os.fsencode(path)
for file in os.listdir(directory):
    filepath = os.fspath(file)
    with open(directory + b"\\" + filepath, "r") as f:
        parse(json.load(f))

outstring = (
            "--- LJ-Expand's environment table containing all functions and data related to it \n"
            + "lje = {}\n\n"
            + "\n\n".join(namespaces)
            + "\n\n"
            + "\n\n".join(output)
            )
with open("\\".join(__file__.split("\\")[:-1]) + "\\modules\\annotations.lua", "w") as f:
    f.write(outstring)

shutil.rmtree(pathout)