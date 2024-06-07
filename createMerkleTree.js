import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import fs from "fs";

// Addresses to include in the Merkle tree
const values = [
  ["0x0000000000000000000000000000000000000001"],
  ["0x0000000000000000000000000000000000000002"],
  ["0x0000000000000000000000000000000000000003"],
  ["0x0000000000000000000000000000000000000004"],
  ["0x0000000000000000000000000000000000000005"],
];

const tree = StandardMerkleTree.of(values, ["address"]);

console.log("Merkle Root:", tree.root);
fs.writeFileSync("tree.json", JSON.stringify(tree.dump()));
