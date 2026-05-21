module.exports = {
  skipFiles: [
    "mocks/",
    "test/",
    "ReentrancyAttacker.sol",
  ],
  measureStatementCoverage: true,
  measureFunctionCoverage: true,
  configureYulOptimizer: true,
  solcOptimizerDetails: {
    peephole: true,
    inliner: true,
    jumpdestRemover: true,
    orderLiterals: true,
    deduplicate: true,
    cse: true,
    constantOptimizer: true,
    yul: true,
  },
};
