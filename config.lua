Config = {}

Config.Framework = 'auto'
Config.ServerName = 'Neutral RP'
Config.Keybind = 'F1'
Config.SettingsCommand = 'radialsettings'
Config.OpenCommand = 'radialmenu'
Config.Debug = false
Config.MaxItems = 8
Config.InteractDistance = 3.0
Config.CenterIcon = 'fa-solid fa-comment'

Config.Defaults = {
    theme = 'dark',
    blur = true,
    behaviour = 'hold',
    sound = true,
    colored = false,
    items = { 'settings', 'phone', 'inventory', 'clothes', 'emotes', 'wallet', 'job', 'vehicle' }
}

Config.Block = {
    dead = true,
    restrained = true
}

Config.Items = {
    { id = 'settings', label = 'item_settings', icon = 'fa-solid fa-gear', color = '#a3aab8', action = { type = 'internal', fn = 'openSettings' } },
    { id = 'phone', label = 'item_phone', icon = 'fa-solid fa-mobile-screen-button', color = '#4fc3f7', action = { type = 'internal', fn = 'openPhone' } },
    { id = 'inventory', label = 'item_inventory', icon = 'fa-solid fa-box-open', color = '#ffb74d', action = { type = 'internal', fn = 'openInventory' } },
    { id = 'clothes', label = 'item_clothes', icon = 'fa-solid fa-shirt', color = '#f06292', submenu = 'clothes' },
    { id = 'emotes', label = 'item_emotes', icon = 'fa-solid fa-person-walking-arrow-loop-left', color = '#ffd54f', action = { type = 'internal', fn = 'openEmotes' } },
    { id = 'wallet', label = 'item_wallet', icon = 'fa-solid fa-wallet', color = '#81c784', submenu = 'wallet' },
    { id = 'job', label = 'item_job', icon = 'fa-solid fa-briefcase', color = '#9575cd', submenu = 'job', hideWhenEmpty = true },
    { id = 'vehicle', label = 'item_vehicle', icon = 'fa-solid fa-car', color = '#64b5f6', submenu = 'vehicle' },
    { id = 'citizen', label = 'item_citizen', icon = 'fa-solid fa-user-group', color = '#e57373', submenu = 'citizen' },
    { id = 'blips', label = 'item_blips', icon = 'fa-solid fa-map-location-dot', color = '#4db6ac', submenu = 'blips' },
    { id = 'housing', label = 'item_housing', icon = 'fa-solid fa-house', color = '#ffa726', submenu = 'housing', hideWhenEmpty = true }
}

Config.HideEmptyItems = true

Config.Housing = {
    enabled = true,
    resource = 'ps-housing',
    color = '#ffa726',
    leaveEvent = 'ps-housing:server:leaveProperty',
    enterEvents = { 'ps-housing:client:enterProperty' },
    exitEvents = { 'ps-housing:client:exitProperty', 'ps-housing:client:leaveProperty' },
    actions = {
        {
            id = 'menu', label = 'house_menu', icon = 'fa-solid fa-house-chimney-window',
            requireOutside = true,
            action = { type = 'command', command = 'housing' }
        },
        {
            id = 'doorbell', label = 'house_doorbell', icon = 'fa-solid fa-bell',
            requireOutside = true,
            action = { type = 'command', command = '' }
        },
        {
            id = 'decorate', label = 'house_decorate', icon = 'fa-solid fa-couch',
            requireInside = true,
            action = { type = 'command', command = '' }
        },
        {
            id = 'leave', label = 'house_leave', icon = 'fa-solid fa-door-open',
            requireInside = true,
            action = { type = 'internal', fn = 'housingLeave' }
        }
    }
}

Config.Phone = {
    command = 'phone'
}

Config.Inventory = {
    command = 'inventory'
}

Config.Emotes = {
    command = 'emotemenu'
}

Config.Wallet = {
    giveCash = true,
    maxGive = 1000000
}

Config.Vehicle = {
    seatChangeMaxSpeed = 15.0,
    searchDistance = 4.0,
    flipDuration = 5000,
    extrasRequireStopped = true
}

Config.Clothing = {
    { id = 'hat', type = 'prop', index = 0, icon = 'fa-solid fa-hat-cowboy', anim = { dict = 'mp_masks@standard_car@ds@', clip = 'put_on_mask', time = 600 } },
    { id = 'glasses', type = 'prop', index = 1, icon = 'fa-solid fa-glasses', anim = { dict = 'clothingspecs', clip = 'take_off', time = 1400 } },
    { id = 'ear', type = 'prop', index = 2, icon = 'fa-solid fa-ear-listen', anim = { dict = 'mp_cp_stolen_tut', clip = 'b_think', time = 900 } },
    { id = 'watch', type = 'prop', index = 6, icon = 'fa-solid fa-clock', anim = { dict = 'nmt_3_rcm-10', clip = 'cs_nigel_dual-10', time = 1200 } },
    { id = 'bracelet', type = 'prop', index = 7, icon = 'fa-solid fa-ring', anim = { dict = 'nmt_3_rcm-10', clip = 'cs_nigel_dual-10', time = 1200 } },
    { id = 'mask', type = 'comp', index = 1, icon = 'fa-solid fa-masks-theater', naked = { male = 0, female = 0 }, anim = { dict = 'mp_masks@standard_car@ds@', clip = 'put_on_mask', time = 800 } },
    { id = 'top', type = 'comp', index = 11, icon = 'fa-solid fa-shirt', naked = { male = 15, female = 15 }, extra = { { index = 8, male = 15, female = 14 }, { index = 3, male = 15, female = 15 } }, anim = { dict = 'clothingtie', clip = 'try_tie_neutral_a', time = 1200 } },
    { id = 'pants', type = 'comp', index = 4, icon = 'fa-solid fa-person', naked = { male = 61, female = 15 }, anim = { dict = 're@construction', clip = 'out_of_breath', time = 1300 } },
    { id = 'shoes', type = 'comp', index = 6, icon = 'fa-solid fa-shoe-prints', naked = { male = 34, female = 35 }, anim = { dict = 'random@domestic', clip = 'pickup_low', time = 1200 } },
    { id = 'gloves', type = 'comp', index = 3, icon = 'fa-solid fa-mitten', naked = { male = 15, female = 15 }, anim = { dict = 'nmt_3_rcm-10', clip = 'cs_nigel_dual-10', time = 1200 } },
    { id = 'bag', type = 'comp', index = 5, icon = 'fa-solid fa-bag-shopping', naked = { male = 0, female = 0 }, anim = { dict = 'anim@heists@ornate_bank@grab_cash', clip = 'intro', time = 1600 } },
    { id = 'vest', type = 'comp', index = 9, icon = 'fa-solid fa-vest', naked = { male = 0, female = 0 }, anim = { dict = 'clothingtie', clip = 'try_tie_negative_a', time = 1200 } },
    { id = 'neck', type = 'comp', index = 7, icon = 'fa-solid fa-user-tie', naked = { male = 0, female = 0 }, anim = { dict = 'clothingtie', clip = 'try_tie_positive_a', time = 1200 } }
}

Config.Trunk = {
    blockedClasses = { 8, 13, 14, 15, 16, 21 },
    offsetY = 0.55,
    offsetZ = 0.28,
    victimCanEscape = false
}

Config.Kidnap = {
    requireRestrained = true,
    distance = 2.0
}

Config.Blips = {
    nearest = 3,
    refreshDistance = 150.0,
    categories = {
        {
            id = 'gas', label = 'blip_gas', icon = 'fa-solid fa-gas-pump', color = '#ffb74d', sprite = 361, colour = 1,
            coords = {
                vec3(49.4, 2778.8, 58.0), vec3(263.9, 2606.5, 44.9), vec3(1039.9, 2671.1, 39.5), vec3(1207.3, 2660.2, 37.9),
                vec3(2539.7, 2594.2, 37.9), vec3(2679.9, 3263.9, 55.2), vec3(2005.1, 3773.9, 32.4), vec3(1687.2, 4929.4, 42.1),
                vec3(1701.3, 6416.0, 32.8), vec3(179.9, 6602.8, 31.9), vec3(-94.5, 6419.6, 31.5), vec3(-2554.9, 2334.4, 33.1),
                vec3(-1800.4, 803.7, 138.7), vec3(-1437.6, -276.7, 46.2), vec3(-2096.2, -320.3, 13.2), vec3(-724.6, -935.2, 19.2),
                vec3(-526.0, -1211.0, 18.2), vec3(-70.2, -1761.8, 29.5), vec3(265.6, -1261.3, 29.3), vec3(819.7, -1028.8, 26.4),
                vec3(1208.9, -1402.6, 35.2), vec3(1181.4, -330.8, 69.3), vec3(620.8, 269.1, 103.1), vec3(2581.3, 362.0, 108.5),
                vec3(176.6, -1562.0, 29.3), vec3(-319.3, -1471.7, 30.5), vec3(1784.3, 3330.6, 41.2)
            }
        },
        {
            id = 'hospital', label = 'blip_hospital', icon = 'fa-solid fa-hospital', color = '#e57373', sprite = 61, colour = 2,
            coords = { vec3(298.6, -584.5, 43.3), vec3(-449.7, -340.8, 34.5), vec3(340.3, -1396.2, 32.5), vec3(1839.6, 3672.9, 34.3), vec3(-247.8, 6331.2, 32.4) }
        },
        {
            id = 'police', label = 'blip_police', icon = 'fa-solid fa-building-shield', color = '#64b5f6', sprite = 60, colour = 29,
            coords = { vec3(428.2, -984.5, 29.7), vec3(-1108.3, -845.2, 19.3), vec3(360.9, -1584.7, 29.3), vec3(638.5, 1.7, 82.8), vec3(1853.2, 3689.6, 34.3), vec3(-448.0, 6013.0, 31.7), vec3(826.8, -1290.0, 28.2) }
        },
        {
            id = 'clothing', label = 'blip_clothing', icon = 'fa-solid fa-shirt', color = '#f06292', sprite = 73, colour = 47,
            coords = {
                vec3(72.3, -1399.1, 29.4), vec3(-703.8, -152.3, 37.4), vec3(-167.9, -299.0, 39.7), vec3(428.7, -800.1, 29.5),
                vec3(-829.4, -1073.7, 11.3), vec3(-1447.8, -242.5, 49.8), vec3(11.6, 6514.2, 31.9), vec3(123.6, -219.4, 54.6),
                vec3(1696.3, 4829.3, 42.1), vec3(618.1, 2759.6, 42.1), vec3(1190.6, 2713.4, 38.2), vec3(-1193.4, -772.3, 17.3),
                vec3(-3172.5, 1048.1, 20.9), vec3(-1108.4, 2708.9, 19.1)
            }
        },
        {
            id = 'barber', label = 'blip_barber', icon = 'fa-solid fa-scissors', color = '#ba68c8', sprite = 71, colour = 0,
            coords = { vec3(-814.3, -183.8, 37.6), vec3(136.8, -1708.4, 29.3), vec3(-1282.6, -1116.8, 7.0), vec3(1931.5, 3729.7, 32.8), vec3(1212.8, -472.9, 66.2), vec3(-32.9, -152.3, 57.1), vec3(-278.1, 6228.5, 31.7) }
        },
        {
            id = 'bank', label = 'blip_bank', icon = 'fa-solid fa-building-columns', color = '#81c784', sprite = 108, colour = 2,
            coords = { vec3(149.9, -1040.5, 29.4), vec3(314.2, -278.6, 54.2), vec3(-350.8, -49.6, 49.0), vec3(-1213.0, -330.4, 37.8), vec3(-2962.6, 482.6, 15.7), vec3(1175.1, 2706.8, 38.1), vec3(241.7, 220.7, 106.3), vec3(-112.2, 6469.3, 31.6) }
        },
        {
            id = 'garage', label = 'blip_garage', icon = 'fa-solid fa-square-parking', color = '#4fc3f7', sprite = 357, colour = 3,
            coords = { vec3(215.8, -810.1, 30.7), vec3(-330.0, -780.3, 33.9), vec3(-1184.0, -1509.6, 4.6), vec3(1737.6, 3710.2, 34.1), vec3(107.3, 6611.8, 31.9), vec3(-796.9, -2022.8, 9.2) }
        },
        {
            id = 'mechanic', label = 'blip_mechanic', icon = 'fa-solid fa-wrench', color = '#a1887f', sprite = 72, colour = 5,
            coords = { vec3(-337.4, -136.9, 39.0), vec3(-1155.5, -2007.2, 13.2), vec3(731.8, -1088.9, 22.2), vec3(1175.0, 2640.0, 37.8), vec3(110.8, 6626.5, 31.8) }
        }
    }
}

Config.Mechanic = {
    repairTime = 10000,
    cleanTime = 6000
}

Config.Taxi = {
    baseFare = 5.0,
    perKm = 12.0,
    minMissionTime = 20,
    maxPayout = 2500,
    payAccount = 'bank',
    pedModels = { 'a_m_y_business_01', 'a_f_y_business_02', 'a_m_m_bevhills_01', 'a_f_y_hipster_02', 'a_m_y_hipster_01', 'a_f_m_tourist_01' },
    locations = {
        vec3(-1037.4, -2737.7, 20.2), vec3(-705.3, -150.9, 37.4), vec3(262.4, -1027.6, 29.2), vec3(-1394.8, -589.4, 30.3),
        vec3(-1175.2, -890.2, 13.9), vec3(356.5, 294.7, 103.5), vec3(-1603.0, -1057.2, 13.0), vec3(1152.3, -432.0, 67.0),
        vec3(-52.1, -1757.5, 29.4), vec3(794.4, -751.4, 26.8), vec3(-3037.9, 590.2, 7.8), vec3(-1824.0, 790.0, 138.2),
        vec3(407.8, -1624.0, 29.3), vec3(-573.7, -1106.0, 22.2), vec3(1693.9, 3757.3, 34.7)
    }
}

Config.Jobs = {
    police = {
        jobs = { 'police', 'sheriff', 'lspd', 'bcso', 'sast' },
        requireDuty = true,
        integration = 'auto',
        color = '#64b5f6',
        actions = {
            { id = 'cuff', label = 'job_cuff', icon = 'fa-solid fa-handcuffs' },
            { id = 'search', label = 'job_search', icon = 'fa-solid fa-magnifying-glass' },
            { id = 'escort', label = 'job_escort', icon = 'fa-solid fa-people-pulling' },
            { id = 'putinveh', label = 'job_putinveh', icon = 'fa-solid fa-car-side' },
            { id = 'takeoutveh', label = 'job_takeoutveh', icon = 'fa-solid fa-person-walking-arrow-right' },
            { id = 'jail', label = 'job_jail', icon = 'fa-solid fa-building-lock' },
            { id = 'revoke', label = 'job_revoke', icon = 'fa-solid fa-id-card-clip' },
            { id = 'status', label = 'job_status', icon = 'fa-solid fa-heart-pulse' }
        }
    },
    ems = {
        jobs = { 'ambulance', 'ems', 'doctor' },
        requireDuty = true,
        integration = 'auto',
        color = '#e57373',
        actions = {
            { id = 'revive', label = 'job_revive', icon = 'fa-solid fa-kit-medical' },
            { id = 'heal', label = 'job_heal', icon = 'fa-solid fa-bandage' },
            { id = 'status', label = 'job_status', icon = 'fa-solid fa-heart-pulse' }
        }
    },
    mechanic = {
        jobs = { 'mechanic', 'bennys', 'lscustoms' },
        requireDuty = false,
        integration = 'auto',
        color = '#a1887f',
        actions = {
            { id = 'tow', label = 'job_tow', icon = 'fa-solid fa-truck-pickup', from = 'tow' },
            { id = 'repair', label = 'job_repair', icon = 'fa-solid fa-screwdriver-wrench' },
            { id = 'clean', label = 'job_clean', icon = 'fa-solid fa-soap' }
        }
    },
    taxi = {
        jobs = { 'taxi' },
        requireDuty = false,
        integration = 'auto',
        color = '#ffd54f',
        actions = {
            { id = 'meter', label = 'job_meter', icon = 'fa-solid fa-gauge-high' },
            { id = 'meterstart', label = 'job_meter_start', icon = 'fa-solid fa-play' },
            { id = 'npc', label = 'job_npc', icon = 'fa-solid fa-user-clock' }
        }
    },
    tow = {
        jobs = { 'tow' },
        requireDuty = false,
        integration = 'auto',
        color = '#ff8a65',
        actions = {
            { id = 'tow', label = 'job_tow', icon = 'fa-solid fa-truck-pickup' },
            { id = 'npc', label = 'job_tow_npc', icon = 'fa-solid fa-user-clock' }
        }
    }
}

Config.Integrations = {
    police = {
        {
            name = 'qbx_police', resource = 'qbx_police',
            actions = {
                cuff = { type = 'client', event = 'police:client:CuffPlayer' },
                search = { type = 'client', event = 'police:client:SearchPlayer' },
                escort = { type = 'client', event = 'police:client:EscortPlayer' },
                putinveh = { type = 'client', event = 'police:client:PutPlayerInVehicle' },
                takeoutveh = { type = 'client', event = 'police:client:SetPlayerOutVehicle' },
                jail = { type = 'client', event = 'police:client:JailPlayer' },
                revoke = { type = 'client', event = 'police:client:SeizeDriverLicense' },
                status = { type = 'client', event = 'police:client:CheckStatus' }
            }
        },
        {
            name = 'qb-policejob', resource = 'qb-policejob',
            actions = {
                cuff = { type = 'client', event = 'police:client:CuffPlayer' },
                search = { type = 'client', event = 'police:client:SearchPlayer' },
                escort = { type = 'client', event = 'police:client:EscortPlayer' },
                putinveh = { type = 'client', event = 'police:client:PutPlayerInVehicle' },
                takeoutveh = { type = 'client', event = 'police:client:SetPlayerOutVehicle' },
                jail = { type = 'client', event = 'police:client:JailPlayer' },
                revoke = { type = 'client', event = 'police:client:SeizeDriverLicense' },
                status = { type = 'client', event = 'police:client:CheckStatus' }
            }
        },
        {
            name = 'esx_policejob', resource = 'esx_policejob',
            actions = {
                cuff = { type = 'server', event = 'esx_policejob:handcuff', target = true },
                search = { type = 'internal', fn = 'searchPlayer', target = true },
                escort = { type = 'server', event = 'esx_policejob:drag', target = true },
                putinveh = { type = 'server', event = 'esx_policejob:putInVehicle', target = true },
                takeoutveh = { type = 'server', event = 'esx_policejob:OutVehicle', target = true },
                jail = { type = 'command', command = 'jail' },
                revoke = { type = 'internal', fn = 'revokeLicense', target = true, args = { '$target', 'drive' } }
            }
        },
        {
            name = 'wasabi_police_v2', resource = 'wasabi_police_v2',
            actions = {
                cuff = { type = 'client', event = 'wasabi_police:handcuffPlayer', args = { 'hard' } },
                search = { type = 'export', resource = 'wasabi_police_v2', fn = 'openJobMenu' },
                escort = { type = 'export', resource = 'wasabi_police_v2', fn = 'openJobMenu' },
                putinveh = { type = 'export', resource = 'wasabi_police_v2', fn = 'openJobMenu' },
                takeoutveh = { type = 'export', resource = 'wasabi_police_v2', fn = 'openJobMenu' },
                jail = { type = 'export', resource = 'wasabi_police_v2', fn = 'openJobMenu' }
            }
        },
        {
            name = 'wasabi_police', resource = 'wasabi_police',
            actions = {
                cuff = { type = 'client', event = 'wasabi_police:handcuffPlayer', args = { 'hard' } },
                search = { type = 'export', resource = 'wasabi_police', fn = 'searchPlayer', target = true, localTarget = true },
                escort = { type = 'export', resource = 'wasabi_police', fn = 'escortPlayer', target = true },
                putinveh = { type = 'client', event = 'wasabi_police:inVehiclePlayer' },
                takeoutveh = { type = 'client', event = 'wasabi_police:outVehiclePlayer' },
                jail = { type = 'command', command = 'jail' }
            }
        },
        {
            name = 'origen_police', resource = 'origen_police',
            actions = {
                jail = { type = 'command', command = 'jail' }
            }
        },
        {
            name = 'p_policejob', resource = 'p_policejob',
            actions = {
                jail = { type = 'command', command = 'jail' }
            }
        }
    },
    ems = {
        {
            name = 'qbx_ambulancejob', resource = 'qbx_ambulancejob',
            actions = {
                revive = { type = 'client', event = 'hospital:client:RevivePlayer' },
                heal = { type = 'client', event = 'hospital:client:TreatWounds' },
                status = { type = 'client', event = 'hospital:client:CheckStatus' }
            }
        },
        {
            name = 'qb-ambulancejob', resource = 'qb-ambulancejob',
            actions = {
                revive = { type = 'client', event = 'hospital:client:RevivePlayer' },
                heal = { type = 'client', event = 'hospital:client:TreatWounds' },
                status = { type = 'client', event = 'hospital:client:CheckStatus' }
            }
        },
        {
            name = 'esx_ambulancejob', resource = 'esx_ambulancejob',
            actions = {
                revive = { type = 'server', event = 'esx_ambulancejob:revive', target = true },
                heal = { type = 'server', event = 'esx_ambulancejob:heal', target = true, args = { '$target', 'small' } }
            }
        },
        {
            name = 'wasabi_ambulance_v2', resource = 'wasabi_ambulance_v2',
            actions = {
                revive = { type = 'client', event = 'wasabi_ambulance:reviveTarget' },
                heal = { type = 'client', event = 'wasabi_ambulance:healTarget' },
                status = { type = 'client', event = 'wasabi_ambulance:diagnosePatient' }
            }
        },
        {
            name = 'wasabi_ambulance', resource = 'wasabi_ambulance',
            actions = {
                revive = { type = 'client', event = 'wasabi_ambulance:reviveTarget' },
                heal = { type = 'client', event = 'wasabi_ambulance:healTarget' },
                status = { type = 'client', event = 'wasabi_ambulance:diagnosePatient' }
            }
        },
        {
            name = 'p_ambulancejob', resource = 'p_ambulancejob',
            actions = {}
        }
    },
    tow = {
        {
            name = 'qbx_towjob', resource = 'qbx_towjob',
            actions = {
                tow = { type = 'client', event = 'qb-tow:client:TowVehicle' },
                npc = { type = 'client', event = 'jobs:client:ToggleNpc' }
            }
        },
        {
            name = 'qb-towjob', resource = 'qb-towjob',
            actions = {
                tow = { type = 'client', event = 'qb-tow:client:TowVehicle' },
                npc = { type = 'client', event = 'jobs:client:ToggleNpc' }
            }
        },
        {
            name = 'kq_towing2', resource = 'kq_towing2',
            actions = {}
        }
    },
    taxi = {
        {
            name = 'qbx_taxijob', resource = 'qbx_taxijob',
            actions = {
                meter = { type = 'client', event = 'qb-taxi:client:toggleMeter' },
                meterstart = { type = 'client', event = 'qb-taxi:client:enableMeter' },
                npc = { type = 'client', event = 'qb-taxi:client:DoTaxiNpc' }
            }
        },
        {
            name = 'qb-taxijob', resource = 'qb-taxijob',
            actions = {
                meter = { type = 'client', event = 'qb-taxi:client:toggleMeter' },
                meterstart = { type = 'client', event = 'qb-taxi:client:enableMeter' },
                npc = { type = 'client', event = 'qb-taxi:client:DoTaxiNpc' }
            }
        },
        { name = 'esx_taxijob', resource = 'esx_taxijob', actions = {} },
        { name = 'gg_taxijob', resource = 'gg_taxijob', actions = {} },
        { name = 'qs-taxijob', resource = 'qs-taxijob', actions = {} },
        { name = 'codem-taxijob', resource = 'codem-taxijob', actions = {} },
        { name = 'fd_taxi', resource = 'fd_taxi', actions = {} }
    },
    mechanic = {},
    fallback = {
        police = {
            search = { type = 'internal', fn = 'searchPlayer', target = true },
            revoke = { type = 'internal', fn = 'revokeLicense', target = true },
            status = { type = 'internal', fn = 'checkStatus' }
        },
        ems = {
            status = { type = 'internal', fn = 'checkStatus' }
        },
        mechanic = {
            repair = { type = 'internal', fn = 'mechRepair' },
            clean = { type = 'internal', fn = 'mechClean' }
        },
        taxi = {
            meter = { type = 'internal', fn = 'taxiMeter' },
            npc = { type = 'internal', fn = 'taxiNpc' }
        },
        tow = {}
    }
}
