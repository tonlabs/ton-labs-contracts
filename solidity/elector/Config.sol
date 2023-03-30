/*
    This file is part of TON OS.

    TON OS is free software: you can redistribute it and/or modify 
    it under the terms of the Apache License 2.0 (http://www.apache.org/licenses/)

    Copyright 2019-2023 (c) EverX
*/

pragma ton-solidity ^ 0.66.0;
pragma AbiHeader expire;
pragma AbiHeader time;
import "IConfig.sol";
import "IElector.sol";
import "Common.sol";

contract Config is IConfig {

    uint32 constant VERSION_MAJOR = 0;
    uint32 constant VERSION_MINOR = 1;

    struct __ValidatorSet {
        uint8 tag; // = 0x12
        uint32 utime_since;
        uint32 utime_until;
        uint16 total;
        uint16 main;
        uint64 total_weight;
        mapping(uint16 => Common.ValidatorAddr) vdict;
    }

    mapping(uint32 => TvmCell) m_cfg_dict;

    // constructor for testing purposes
    constructor() public {
        {
            TvmBuilder b;
            b.storeUnsigned(0x5555555555555555555555555555555555555555555555555555555555555555, 256);
            m_cfg_dict[0] = b.toCell();
        }
        {
            TvmBuilder b;
            b.storeUnsigned(0x3333333333333333333333333333333333333333333333333333333333333333, 256);
            m_cfg_dict[1] = b.toCell();
        }
        {
            TvmBuilder b;
            b.store(uint8(0x1a));
            b.storeTons(1 << 30);
            b.storeTons(1);
            b.storeTons(512);
            m_cfg_dict[13] = b.toCell();
        }
        {
            uint32 elect_for          = 6000;
            uint32 elect_begin_before = 3600;
            uint32 elect_end_before   = 1800;
            uint32 stake_held         = 32768;
            TvmBuilder b;
            b.store(elect_for, elect_begin_before, elect_end_before, stake_held);
            m_cfg_dict[15] = b.toCell();
        }
        {
            uint16 max_validators  = 7;
            uint16 main_validators = 100;
            uint16 min_validators  = 3;
            TvmBuilder b;
            b.store(max_validators, main_validators, min_validators);
            m_cfg_dict[16] = b.toCell();
        }
        {
            uint128 min_stake = 2_000_000_000;
            uint128 max_stake = 50_000_000_000;
            uint128 min_total_stake = 10_000_000_000;
            uint32 max_stake_factor = 3 << 16;
            TvmBuilder b;
            b.storeTons(min_stake);
            b.storeTons(max_stake);
            b.storeTons(min_total_stake);
            b.store(max_stake_factor);
            m_cfg_dict[17] = b.toCell();
        }
        {
            mapping(uint32 => TvmSlice) storage_dict = emptyMap;
            {
                TvmBuilder b;
                b.storeUnsigned(0xCC, 8);
                b.storeUnsigned(0, 32); // utime_since
                b.storeUnsigned(0, 64); // bit_price_ps
                b.storeUnsigned(0, 64); // cell_price_ps
                b.storeUnsigned(0, 64); // mc_bit_price_ps
                b.storeUnsigned(0, 64); // mc_cell_price_ps
                storage_dict[0] = b.toSlice();
            }
            {
                TvmBuilder b;
                b.store(storage_dict);
                m_cfg_dict[18] = b.toSlice().loadRef();
            }
        }
        {
            TvmBuilder b;
            b.storeUnsigned(0xD1, 8);
            b.storeUnsigned(0, 64);
            b.storeUnsigned(0, 64);
            b.storeUnsigned(0xDE, 8);
            b.storeUnsigned(0, 64); // gas_price
            b.storeUnsigned(0xFFFFFFFFFF, 64); // gas_limit
            b.storeUnsigned(0xFFFFFFFFFF, 64); // special_gas_limit
            b.storeUnsigned(0xFFFFFF, 64); // gas_credit
            b.storeUnsigned(0xFFFFFFFFFFFFFFFF, 64);
            b.storeUnsigned(0, 64);
            b.storeUnsigned(0, 64);
            m_cfg_dict[20] = b.toCell();
            m_cfg_dict[21] = b.toCell();
        }
        {
            TvmBuilder b;
            b.storeUnsigned(0xEA, 8);
            b.storeUnsigned(0, 64); // lump_price
            b.storeUnsigned(0, 64); // bit_price
            b.storeUnsigned(0, 64); // cell_price
            b.storeUnsigned(0, 32); // ihr_price_factor
            b.storeUnsigned(0, 16); // first_frac
            b.storeUnsigned(0, 16); // next_frac
            m_cfg_dict[24] = b.toCell();
            m_cfg_dict[25] = b.toCell();
        }
        {
            TvmBuilder b;
            b.store(false);
            m_cfg_dict[31] = b.toCell();
        }
        {
            Common.ValidatorSet vset;
            vset.tag          = 0x12;
            vset.utime_since  = 0;
            vset.utime_until  = 6000;
            vset.total        = 0;
            vset.main         = 0;
            vset.total_weight = 0;
            vset.vdict        = emptyMap;

            TvmBuilder b;
            b.store(vset);
            m_cfg_dict[34] = b.toCell();
        }
    }

    function check_validator_set(TvmCell vset) internal pure returns (uint32, uint32) {
        Common.ValidatorSet v = vset.toSlice().decode(Common.ValidatorSet);
        return (v.utime_since, v.utime_until);
    }

    function send_confirmation(uint64 query_id) internal pure {
        IElector(msg.sender).config_set_confirmed_ok{flag: 64, value: 0}(query_id);
    }

    function send_error(uint64 query_id) internal pure {
        IElector(msg.sender).config_set_confirmed_err{flag: 64, value: 0}(query_id);
    }

    function send_slash_confirmation(uint64 query_id) internal pure {
        IElector(msg.sender).config_slash_confirmed_ok{flag: 64, value: 0}(query_id);
    }

    function send_slash_error(uint64 query_id) internal pure {
        IElector(msg.sender).config_slash_confirmed_err{flag: 64, value: 0}(query_id);
    }

    function set_next_validator_set(uint64 query_id, TvmCell vset) override
        functionID(0x4e565354) public {
        (TvmCell cfg1, bool f) = tvm.rawConfigParam(1);
        if (!f) {
            return;
        }
        uint256 elector_addr = cfg1.toSlice().loadUnsigned(256);
        bool ok = false;
        if (msg.sender.value == elector_addr) {
            tvm.accept();
            // message from elector smart contract
            // set next validator set
            (uint32 t_since, uint32 t_until) = check_validator_set(vset);
            ok = (t_since > now) && (t_until > t_since);
        }
        if (ok) {
            m_cfg_dict[36] = vset;
            // send confirmation
            send_confirmation(query_id);
        } else {
            send_error(query_id);
        }
    }

    function set_slashed_validator_set(uint64 query_id, TvmCell vset) override
        functionID(0x4e565355) public {
        (int8 my_wc, /* uint256 */) = address(this).unpack();
        if (my_wc != -1) {
            return;
        }
        (TvmCell cfg1, bool f) = tvm.rawConfigParam(1);
        if (!f) {
            return;
        }
        uint256 elector_addr = cfg1.toSlice().loadUnsigned(256);
        bool ok = false;
        if (msg.sender.value == elector_addr) {
            tvm.accept();
            // message from elector smart contract
            // set slashed validator set
            (uint32 t_since, uint32 t_until) = check_validator_set(vset);
            ok = (t_since > now) && (t_until > t_since);
        }
        if (ok) {
            m_cfg_dict[35] = vset;
            // send confirmation
            send_slash_confirmation(query_id);
        } else {
            send_slash_error(query_id);
        }
    }

    // we accept external corrtly signed messages only
    modifier requireOwner {
        require(tvm.pubkey() != 0, 101);
        require(tvm.pubkey() == msg.pubkey(), 100);
        _;
    }

    function set_config_param(uint32 index, TvmCell data) public externalMsg requireOwner {
        require(data.toSlice().depth() <= 128, 39);
        tvm.accept();
        m_cfg_dict[index] = data;
    }

    function set_public_key(uint256 pubkey) public externalMsg requireOwner {
        tvm.accept();
        tvm.setPubkey(pubkey);
    }

    function set_elector_code(TvmCell code, TvmCell data) public externalMsg view requireOwner {
        require(code.depth() <= 128, 39);
        require(data.depth() <= 128, 39);
        (TvmCell cfg1, bool f) = tvm.rawConfigParam(1);
        if (!f) {
            return;
        }
        tvm.accept();
        uint256 elector_addr = cfg1.toSlice().loadUnsigned(256);
        uint32 query_id = now;
        IElector(address.makeAddrStd(-1, elector_addr))
            .upgrade_code{value: 1 << 30, flag: 0}(query_id, code, data);
    }

    function set_code(TvmCell code) override public externalMsg requireOwner {
        require(code.depth() <= 128, 39);
        tvm.setcode(code);
        tvm.setCurrentCode(code);
        onCodeUpgrade();
    }

    // we accept internal message from approved contract only
    modifier requireOwnerContract {
        (TvmCell cfg5, bool f) = tvm.rawConfigParam(5);
        require(f, 501);
        uint256 addr = cfg5.toSlice().loadUnsigned(256);
        require(msg.sender == address.makeAddrStd(-1, addr), 502);
        _;
    }

    function change_public_key(uint256 pubkey) public internalMsg override requireOwnerContract {
        tvm.accept();
        tvm.setPubkey(pubkey);
    }

    function change_config_param(uint32 index, TvmCell data) public internalMsg override requireOwnerContract {
        require(data.toSlice().depth() <= 128, 39);

        tvm.accept();
        m_cfg_dict[index] = data;
    }

    function change_elector_code(TvmCell code, TvmCell data) public internalMsg pure override requireOwnerContract {
        require(code.depth() <= 128, 39);
        require(data.depth() <= 128, 39);
        (TvmCell cfg1, bool f) = tvm.rawConfigParam(1);
        if (!f) {
            return;
        }
        tvm.accept();
        uint256 elector_addr = cfg1.toSlice().loadUnsigned(256);
        uint32 query_id = now;
        IElector(address.makeAddrStd(-1, elector_addr))
            .upgrade_code{value: 1 << 30, flag: 0}(query_id, code, data);
    }

    function change_code(TvmCell code) public internalMsg override pure requireOwnerContract {
        require(code.depth() <= 128, 39);
        tvm.setcode(code);
        tvm.setCurrentCode(code);
        onCodeUpgrade();
    }

    function onCodeUpgrade() private pure functionID(2) {
        tvm.accept();
        tvm.exit();
    }

    function setcode_confirmation(uint64 query_id, uint32 body) override
        functionID(0xce436f64) public {
    }

    onTickTock(bool /* is_tock */) external {
        optional(TvmCell) c = m_cfg_dict.fetch(36);
        bool updated = false;
        if (c.hasValue()) {
            // check whether we have to set next_vset as the current validator set
            TvmCell next_vset = c.get();
            TvmSlice ds = next_vset.toSlice();
            if (ds.bits() >= 40) {
                (uint8 tag, uint32 since) = ds.decode(uint8, uint32);
                if ((since <= now) && (tag == 0x12)) {
                    // next validator set becomes active!
                    optional(TvmCell) cur_vset = m_cfg_dict.getSet(34, next_vset);
                    m_cfg_dict.getSet(32, cur_vset.get());
                    delete m_cfg_dict[36];
                    updated = true;
                }
            }
        }
        if (!updated) {
            c = m_cfg_dict.fetch(35);
            if (c.hasValue()) {
                TvmCell slashed_vset = c.get();
                TvmSlice ds = slashed_vset.toSlice();
                if (ds.bits() >= 40) {
                    (uint8 tag, uint32 since) = ds.decode(uint8, uint32);
                    if ((since <= now) && (tag == 0x12)) {
                        m_cfg_dict.getSet(34, slashed_vset);
                        delete m_cfg_dict[35];
                        updated = true;
                    }
                }
            }
        }
        if (!updated) {
            // if nothing has been done so far, scan a random voting proposal instead
            //scan_random_proposal(); TODO
        }
    }

    onBounce(TvmSlice slice) external {
    }

    receive() external {
    }

    function reset_utime_until() public {
        tvm.accept();
        TvmCell c = m_cfg_dict[34];
        Common.ValidatorSet vset = c.toSlice().decode(Common.ValidatorSet);
        vset.utime_until = now;
        TvmBuilder b;
        b.store(vset);
        m_cfg_dict[34] = b.toCell();
        // delete next vset to force announce_new_elections
        delete m_cfg_dict[36];
    }

    function get_config_param(uint32 index) public view returns (TvmCell) {
        return m_cfg_dict[index];
    }

    function get_vset(uint32 id) private view returns (__ValidatorSet) {
        optional(TvmCell) c = m_cfg_dict.fetch(id);
        if (c.hasValue()) {
            __ValidatorSet vset = c.get().toSlice().decode(__ValidatorSet);
            return vset;
        } else {
            __ValidatorSet vset;
            return vset;
        }
    }

    // Get previous validator set in a structured form
    function get_previous_vset() public view returns (__ValidatorSet) {
        return get_vset(32);
    }

    // Get current validator set in a structured form
    function get_current_vset() public view returns (__ValidatorSet) {
        return get_vset(34);
    }

    // Get current slashed validator set in a structured form
    function get_slashed_vset() public view returns (__ValidatorSet) {
        return get_vset(35);
    }

    // Get next validator set in a structured form
    function get_next_vset() public view returns (__ValidatorSet) {
        return get_vset(36);
    }

    function public_key() public view returns (uint256) {
        return tvm.pubkey();
    }

    // returns version of elector (major, minor)
    function get_version() public pure returns (uint32, uint32) {
        return (VERSION_MAJOR, VERSION_MINOR);
    }

    function seqno() public pure returns (uint32) { return 0xFFFFFFFF; }
}
