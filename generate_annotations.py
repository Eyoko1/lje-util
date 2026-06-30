# lje-util
# Generates the annotations for LJE by parsing the JSON files

# Type-checking in python is very irritating
# type: ignore

import os
import json
import typing

JSONInstance = typing.Union[dict[str, "JSONInstance"], list["JSONInstance"], str, int, float, bool]

namespaces = []
output = []

path = input("Path to 'lj-expand/docs/api':\t")

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
        namespaces.append(f"--> {data['description']}\nlje.{namespace} = {{}}")
    
    for const in constants:
        if (isbase and not const['name'].startswith("lje.")):
            continue # Don't add polyfills and stuff like that

        description = const['description']
        if type(description) is list:
            description = "".join(description)
        else:
            description = description.replace("\n", " ")

        output.append(f"--> {description}")
        output.append(f"--- @type {const['type']}")
        output.append(f"{cprefix}{const['name']} = nil")
    
    for function in functions:
        returns = []
        for ret in function['returns']:
            string: str = ret['type']
            if (string.find("...") != -1):
                string = "..."
            returns.append(string)

        if (len(returns) == 0):
            returns.append("nil")

        description = function['description']
        if type(description) is list:
            description = "".join(description)
        else:
            description = description.replace("\n", " ")

        #output.append(f"--> {description}")
        #output.append(f"--- @type fun({', '.join(params)}): {', '.join(returns)}")
        #output.append(f"{fprefix}{function['name']} = nil")

        output.append(f"--> {description}")

        params = []
        for param in function["params"]:
            output.append(f"--- @param {param['name']} {param['type']} {param['description']}")
            params.append(param['name'])
        
        output.append("--- @return " + ", ".join(returns))
        output.append(f"function {fprefix}{function['name']}({', '.join(params)}) end --- @diagnostic disable-line")

directory = os.fsencode(path)
for file in os.listdir(directory):
    filepath = os.fspath(file)
    with open(directory + b"\\" + filepath, "r") as f:
        parse(json.load(f))

outstring = (
            "--> LJ-Expand's environment table containing all functions and data related to it \n"
            + "lje = {}\n"
            + "\n".join(namespaces)
            + "\n".join(output)
            )
with open("\\".join(__file__.split("\\")[:-1]) + "\\modules\\annotations.lua", "w") as f:
    f.write(outstring)