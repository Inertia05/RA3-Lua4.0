---This script is used to test the Lua API functions for RA3 Corona Mod.
---Press K to test the API functions step by step.
---Press CTRL + K to reset the test step to the previous one.
---Press L to skip to the next test step.
---Test result will be displayed in the lower left message area in the game.
-- 注册按键：K键，命令码为 1
exRegisterHotKey(75, 0, 1)
-- 注册按键：CTRL + K键，命令码为 2
exRegisterHotKey(75, 17, 2)
-- 注册按键：L键，命令码为 3
exRegisterHotKey(76, 0, 3)

-- 初始化测试步骤
test_step = 1

function _ALERT(s)
    exMessageAppendToMessageArea("LUA ALERT: " .. s)
end

--- 处理热键事件
--- @param playerName string 玩家脚本名字
--- @param commandCode number 命令码, 由 exRegisterHotKey 注册
--- @param mouseWorldPos table 鼠标世界位置{X, Y, Z}，如果鼠标不在游戏窗口内，这个值是nil
--- @return nil
function onUserHotKeyEvent(playerName, commandCode, mouseWorldPos)
    -- 检查命令码是否匹配
    if commandCode == 1 then
        -- DEBUG VARIABLES 内置到 onUserHotKeyEvent 函数中
        local fighter = GetObjectByScriptName("APOLLO")  -- 获取fighter对象
        local x, y, z = ObjectGetPosition(fighter)       -- 获取fighter当前位置
        local fxName = "AlliedBigExplosionFireMushroom"  -- 特效名称
        local unit_id = ObjectGetId(fighter)             -- fighter的ID
        local fxList = "FX_SOV_SupportBomberDieExplosion" -- 特效列表
        --- FXList 示例: (来自FXListSoviet.xml)
        --- 	<FXList id="FX_SOV_SupportBomberDieExplosion">
        ---     <NuggetList>
        ---         <Sound Value="RA3VehicleExplosionMedium" />
        ---     </NuggetList>
        --- </FXList>

        exMessageAppendToMessageArea("Current test step: " .. test_step)

        -- 根据测试步骤执行不同的API测试
        if test_step == 1 then
            -- 检查 exFXShowFXTemplate 是否存在
            if exFXShowFXTemplate ~= nil then
                -- 测试特效播放功能 (FXParticleSystemTemplate)
                exFXShowFXTemplate(fxName, x, y, z)
                exMessageAppendToMessageArea("Player name: <" .. playerName .. ">, command code: <" .. commandCode .. ">, mouseWorldPos: <" .. tostring(mouseWorldPos) .. ">")
                exMessageAppendToMessageArea("Test Step 1: FXParticleSystemTemplate effect played on fighter")
            else
                exMessageAppendToMessageArea("Error: exFXShowFXTemplate function is not defined")
            end
        elseif test_step == 2 then
            -- 检查 exFXShowFXList 是否存在
            if exFXShowFXList ~= nil then
                -- 测试特效播放功能 (FXShowFXList)
                exFXShowFXList(fxList, x, y, z)
                exMessageAppendToMessageArea("Test Step 2: FXShowFXList effect played on fighter")
            else
                exMessageAppendToMessageArea("Error: exFXShowFXList function is not defined")
            end
        elseif test_step == 3 then
            -- 检查 exCounterSetByName 和 exCounterGetByName 是否存在
            if exCounterSetByName ~= nil and exCounterGetByName ~= nil then
                -- 测试计数器功能
                exCounterSetByName("FighterSpawnCount", 5)
                local counterValue = exCounterGetByName("FighterSpawnCount")
                exMessageAppendToMessageArea("Test Step 3: Counter 'FighterSpawnCount' set to 5, value: " .. counterValue)
            else
                exMessageAppendToMessageArea("Error: exCounterSetByName or exCounterGetByName function is not defined")
            end
        elseif test_step == 4 then
            -- 检查 exTerrainGetHeightByPos 和 exTerrainGetTextureNameByPos 是否存在
            if exTerrainGetHeightByPos ~= nil and exTerrainGetTextureNameByPos ~= nil then
                -- 测试地形功能
                local groundHeight = exTerrainGetHeightByPos(x, y)
                local textureName = exTerrainGetTextureNameByPos(x, y)
                exMessageAppendToMessageArea("Test Step 4: Ground height at fighter position: " .. groundHeight .. ", texture: " .. textureName)
            else
                exMessageAppendToMessageArea("Error: exTerrainGetHeightByPos or exTerrainGetTextureNameByPos function is not defined")
            end
        elseif test_step == 5 then 
            -- 检查 exCameraAdjustPos 是否存在
            if exCameraAdjustPos ~= nil then --测试结果函数不存在
                -- 测试相机调整功能
                exCameraAdjustPos(x + 10, y + 10, z + 10)
                exMessageAppendToMessageArea("Test Step "..test_step..": Camera adjusted to 10 units away from fighter")
            else
                exMessageAppendToMessageArea("Error: exCameraAdjustPos function is not defined")
            end
        elseif test_step == 6 then
            -- 检查 exInfoBoxTopCenterShowForPlayer 是否存在
            if exInfoBoxTopCenterShowForPlayer ~= nil then -- 测试结果没有显示框框
                -- 测试显示提示框功能
                exInfoBoxTopCenterShowForPlayer(playerName, "SCRIPT:HELLOWORLD", 5)
                exMessageAppendToMessageArea("Test Step "..test_step..": Info box showed for 5 seconds for player: " .. playerName)
            else
                exMessageAppendToMessageArea("Error: exInfoBoxTopCenterShowForPlayer function is not defined")
            end
        elseif test_step == 7 then
            -- 检查 exObjectDealSecondaryDamage 是否存在
            if exObjectDealSecondaryDamage ~= nil then --测试结果函数不存在
                -- 测试物体伤害功能
                exObjectDealSecondaryDamage(unit_id, 50)
                exMessageAppendToMessageArea("Test Step "..test_step..": Fighter took 50 points of freezing damage")
            else
                exMessageAppendToMessageArea("Error: exObjectDealSecondaryDamage function is not defined")
            end
        elseif test_step == 8 then
            -- 检查 exObjectGetCurrentHealth 和 exObjectGetMaxHealth 是否存在
            if exObjectGetCurrentHealth ~= nil and exObjectGetMaxHealth ~= nil then -- 测试结果函数不存在
                -- 测试血量功能
                local currentHealth = exObjectGetCurrentHealth(unit_id)
                local maxHealth = exObjectGetMaxHealth(unit_id)
                exMessageAppendToMessageArea("Test Step "..test_step..": Fighter current health: " .. currentHealth .. ", max health: " .. maxHealth)
            else
                exMessageAppendToMessageArea("Error: exObjectGetCurrentHealth or exObjectGetMaxHealth function is not defined")
            end
        elseif test_step == 9 then
            -- 检查 exShowFloatingIntAtObject 是否存在
            if exShowFloatingIntAtObject ~= nil then -- 测试结果函数不存在
                -- 测试漂浮数字显示功能
                exShowFloatingIntAtObject(unit_id, 9999)
                exMessageAppendToMessageArea("Test Step "..test_step..": Floating number '9999' displayed above fighter")
            else
                exMessageAppendToMessageArea("Error: exShowFloatingIntAtObject function is not defined")
            end
        elseif test_step == 10 then
            -- 检查 exObjectTintColor 是否存在
            if exObjectTintColor ~= nil then
                -- 测试物体着色功能
                exObjectTintColor(unit_id, 255, 0, 0, 1, 1, 5, 1, 1)
                exMessageAppendToMessageArea("Test Step "..test_step..": Fighter tinted red and blinking")
            else
                exMessageAppendToMessageArea("Error: exObjectTintColor function is not defined")
            end
        end

        -- 进入下一个测试步骤
        test_step = test_step + 1
        if test_step > 10 then
            test_step = 1  -- 重置测试步骤，重新开始
        end
    elseif commandCode == 2 then
        -- 重置测试步骤
        test_step = test_step - 2
        exMessageAppendToMessageArea("Test steps reset to: " .. test_step)
    elseif commandCode == 3 then
        -- test_step + 1
        test_step = test_step + 1
        exMessageAppendToMessageArea("Test steps skip(+1) to: " .. test_step)
    end
end
