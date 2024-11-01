import { readFileSync } from "node:fs";
import Arweave from 'arweave';
import { message, createDataItemSigner, result } from "@permaweb/aoconnect";

const RELAY_LUA_MODULE = readFileSync("./relay.lua").toString();

const arweave = Arweave.init({});

const wallet = await arweave.wallets.generate();
const processId = "0TCTmjHjq2i-GKUmd6w5BeUPOBCG8KK7wNhyE4bK04g";

const uploadModule = async (handler,module) => {
    try {
        // The only 2 mandatory parameters here are process and signer
        let messageId = await message({
    
            // The arweave TXID of the process, this will become the "target".
            // This is the process the message is ultimately sent to.
    
            process: processId,
            // Tags that the process will use as input.
            tags: [
                { name: "Action", value: handler },
            ],
            data:module,
            // A signer function used to build the message "signature"
            signer: createDataItemSigner(wallet),
        })
    
        let { Messages, Spawns, Output, Error } = await result({
            // the arweave TXID of the message
            message: messageId,
            // the arweave TXID of the process
            process: processId,
        });
        console.log(Messages)
        console.log(Spawns)
        console.log(Output)
        console.log(Error)
    } catch (e) {
        console.log(e)
    }
}

await uploadModule("Relay_Lua_Module",RELAY_LUA_MODULE)