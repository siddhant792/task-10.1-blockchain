const SupplyChain = artifacts.require("SupplyChain");

contract("SupplyChain", (accounts) => {
  const manufacturer = accounts[0];
  const retailer1 = accounts[1];
  const retailer2 = accounts[2];
  const consumer = accounts[3];

  let instance;

  before(async () => {
    instance = await SupplyChain.deployed();
  });

  it("should assign Manufacturer role to the contract deployer", async () => {
    const role = await instance.roles(manufacturer);
    assert.equal(role.toString(), "0", "Manufacturer role should be 0");
  });

  it("should add a Retailer role", async () => {
    await instance.addRetailer(retailer1, { from: manufacturer });
    const role = await instance.roles(retailer1);
    assert.equal(role.toString(), "1", "Retailer role should be 1");
  });

  it("should fail to mint a product for a non-retailer", async () => {
    try {
      await instance.mintProduct(consumer, 1, "Product 1", "Origin 1", { from: manufacturer });
      assert.fail("Minting should fail because recipient is not a retailer");
    } catch (error) {
      assert.include(error.message, "Recipient must be a retailer", "Error message should contain 'Recipient must be a retailer'");
    }
  });

  it("should mint a product for a Retailer", async () => {
    await instance.mintProduct(retailer1, 1, "Product 1", "Origin 1", { from: manufacturer });
    const product = await instance.getProduct(1);
    assert.equal(product[0], "Product 1", "Product name should be Product 1");
    assert.equal(product[1], "Origin 1", "Product origin should be Origin 1");
    assert.equal(product[3], retailer1, "Product owner should be retailer1");
  });

  it("should allow a Retailer to transfer a product to a Consumer", async () => {
    await instance.transferProduct(1, consumer, { from: retailer1 });
    const product = await instance.getProduct(1);
    assert.equal(product[3], consumer, "Product owner should be consumer");
  });

  it("should fail to transfer a product if sender is not the owner", async () => {
    // First, add retailer2 as a valid retailer so that the test doesn't fail due to role
    await instance.addRetailer(retailer2, { from: manufacturer });

    // Try to transfer the product from retailer2 (who is not the owner)
    try {
      await instance.transferProduct(1, retailer1, { from: retailer2 });
      assert.fail("Transfer should fail because sender is not the owner");
    } catch (error) {
      assert.include(error.message, "Not the owner of the product", "Error message should contain 'Not the owner of the product'");
    }
  });
});
