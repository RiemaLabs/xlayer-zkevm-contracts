// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.22;

import "../../interfaces/IPolygonDataCommitteeErrors.sol";
import "../../interfaces/IDataAvailabilityProtocol.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "nuport-contracts/src/lib/verifier/DAVerifier.sol";

/*
 * Contract responsible managing the data committee that will verify that the data sent for a validium is singed by a committee
 * It is advised to give the owner of the contract to a timelock contract once the data committee is set
 */
contract Nubit is
    IDataAvailabilityProtocol,
    OwnableUpgradeable
{

    // Name of the data availability protocol
    string internal constant _PROTOCOL_NAME = "Nubit";

    uint256 internal constant _BLOB_POINTER_SIZE = 89;

    error InvalidArgumentLength(uint256 expectedGreaterThan, uint256 actual);

    /**
     * Disable initalizers on the implementation following the best practices
     */
    constructor() {
        _disableInitializers();
    }

    function initialize() external initializer {
        // Initialize OZ contracts
        __Ownable_init_unchained();
    }

    /**
     * @notice Verifies that the given signedHash has been signed by requiredAmountOfSignatures committee members
     * @param proofData Byte array containing the encoded IDAOracle & SharesProof
     */
    function verifyMessage(
        bytes32, bytes calldata blobpointerAndProof
    ) external view {
        if (blobpointerAndProof.length < _BLOB_POINTER_SIZE) {
            revert InvalidArgumentLength(_BLOB_POINTER_SIZE,blobpointerAndProof.length);
        }

        (IDAOracle bridge, SharesProof memory sharesProof) = abi.decode(blobpointerAndProof[_BLOB_POINTER_SIZE:] , (IDAOracle, SharesProof));
        if (sharesProof.attestationProof.tupleRootNonce == 0) return;
        (bool result,) = DAVerifier.verifySharesToDataRootTupleRoot(bridge, sharesProof);
        require(result, "Nuport verification failed");
    }


    /**
     * @notice Return the protocol name
     */
    function getProcotolName() external pure override returns (string memory) {
        return _PROTOCOL_NAME;
    }
}
