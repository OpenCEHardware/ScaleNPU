#!/usr/bin/env python3

import argparse, json, sys, yaml

parser = argparse.ArgumentParser()
parser.add_argument('--top', required=True, help='top module name')
parser.add_argument('syntax_tree', help='output of verible-verilog-syntax --printtree --export_json')
args = parser.parse_args()

with open(args.syntax_tree) as syntax_file:
    syntax = json.load(syntax_file)

assert type(syntax) is dict, f'Bad syntax tree file: {repr(args.syntax_tree)}'

top = args.top
header = None

for source_file in syntax.values():
    syntax_tree = source_file.get('tree', {})

    if syntax_tree.get('tag') != 'kDescriptionList':
        continue

    for child in syntax_tree.get('children', []):
        if not child or child.get('tag') != 'kModuleDeclaration':
            continue

        for subchild in child.get('children', []):
            if not subchild or subchild.get('tag') != 'kModuleHeader':
                continue

            for inner in subchild.get('children', []):
                if inner and inner.get('tag') == 'SymbolIdentifier' and inner.get('text') == top:
                    header = subchild
                    break

            if header is not None:
                break

        if header is not None:
            break

    if header is not None:
        break

if header is None:
    raise Exception(f'Module {repr(top)} was not found in the syntax tree')

inputs = []
clocks = []
resets = []
outputs = []

paren_group = {}
for child in header.get('children', []):
    if child and child.get('tag') == 'kParenGroup':
        paren_group = child
        break

port_list = {}
for child in paren_group.get('children', []):
    if child and child.get('tag') == 'kPortDeclarationList':
        port_list = child
        break

for child in port_list.get('children', []):
    if not child or child.get('tag') != 'kPortDeclaration':
        continue

    port_name = None
    is_output = None

    for subchild in child.get('children', []):
        if not subchild:
            continue

        tag = subchild.get('tag')
        if tag == 'input':
            is_output = False
        elif tag == 'output':
            is_output = True
        elif tag == 'kUnqualifiedId':
            for inner in subchild.get('children', []):
                if inner and inner.get('tag') == 'SymbolIdentifier':
                    port_name = inner.get('text')

    if port_name is None or is_output is None:
        continue
    elif is_output:
        outputs.append(port_name)
    else:
        port_lower = port_name.lower()

        if 'clock' in port_lower or 'clk' in port_lower:
            clocks.append(port_name)
        elif 'reset' in port_lower or 'rst' in port_lower:
            resets.append(port_name)
        else:
            inputs.append(port_name)

out = {
    "DUT_inputs": [{"clocks": clocks}, {"resets": resets}] + inputs,
    "DUT_outputs": outputs,
}

yaml.dump(out, sys.stdout)
