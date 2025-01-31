import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensures users can create valid policies",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const user1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall(
        "safe-stream",
        "add-verified-source",
        [types.ascii("youtube.com")],
        deployer.address
      ),
      Tx.contractCall(
        "safe-stream",
        "create-policy",
        [types.uint(200000), types.uint(1000000), types.ascii("youtube.com")],
        user1.address
      )
    ]);
    
    assertEquals(block.receipts.length, 2);
    assertEquals(block.height, 2);
    block.receipts[1].result.expectOk().expectBool(true);
  },
});

Clarinet.test({
  name: "Ensures premium payments update pool balance",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const user1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall(
        "safe-stream", 
        "pay-premium",
        [],
        user1.address
      )
    ]);

    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk().expectBool(true);
  },
});

Clarinet.test({
  name: "Ensures valid claims can be processed",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const user1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall(
        "safe-stream",
        "file-claim",
        [types.uint(100000)],
        user1.address
      )
    ]);

    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk().expectBool(true);
  },
});
