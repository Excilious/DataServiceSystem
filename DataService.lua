--[[
  [Name]: DataService
  [Date]: 10/12/22
  [About]: This manages and saves/gets the users data. This would also send the data towards the newly joined user. You must enable API services and 
  use RemoteEvent called GetDataAsync (Name can be changed within the variables below). This would also include a log system in which keeps track of every event.
]]

local Service = {};
local Logs = {}; --This can be used to keep track of any events; just in case of any rogue changes that can break the game.
local ReplicatedStorage = game:GetService("ReplicatedStorage") --You can edit where the removeevents and remotefunctions are stored. For now they are stored in rs.
local DataStoreService = game:GetService("DataStoreService");
local ProfileDatabase =  DataStoreService:GetDataStore("Profile"); --This would be where your profile would be stored within.
local DataEvent = {};
local EventName = "GetDataAsync" --This would be the remote event where the client would request a grab of the user data. You can fetch data during the runtime.

Services.DataSaved = {};
local SaveDataWhenAvailable = false; --This would save the data another time when the server is available.
local BindNewCycles = false; --Newly added catagories would not be added within the users data. If added you may remove the subsection but the user will lose their data.
local UserData = {} --This would be the place where we can store our data
local DefaultData = { 

--[[This would be the default data if the user is new. You can add subcatagories like adding a dictionary. 
Keep in mind, the subcatagories you made would be saved per session cycle. New cycles would not be added if the BindNewCycles is not enabled.

Please use the format:
  [Catagory] = {
    [Value within catagory] = Can be within a wide range of values (Dictionary and numerical/alphabetical values are more easier to use)
  }
]]

  ["Weapons"] = {
    ["Owned"] = {};
    ["Equipped"] = {};
  }
}

function Service:FetchAvailableLogs(LogType)
  if LogType == "All" then
    return Logs;
  else
    local TempLogs = {};
    for _,idata in pairs(Logs) do
      if idata.EventType == LogType then
          table.insert(TempLogs,idata);
      end
    end
  end
end

Services.ReloadData = function(Player)
  if (not BindNewCycles) then return end;
  for Subsection,Values in pairs(DefaultData) do
    if UserData[Player.Name][Subsection] == nil then
      UserData[Player.Name][Subsection] = Values;
    end
  end
end

Services.FetchReferance = function(Player,ReferanceName)
  local UpdateTable = {};
  --[[We would then need to fetch the referance (The items for your inventory system. You can add different
  info within referance eg. ItemName, ItemImage, About ect.]]
  local UnknownItemsOfReferance = script:GetChildren() --This would get everything below. We can filter this towards our modulescripts (referance)
  for _,Type in pairs(UnknownItemsOfReferance) do
    if Type:IsA("ModuleScript") then
      --[[We now know that one of the objects is a modulescript. We can then access it and make it globally available.]]--
       UpdateTable[Type.Name] = require(Type); -- This would save the contents of the modulescript within a dictionary. We can access this later.
    end
  end
  _G.ServiceData = UpdateTable; 
  --[[This would make the table global. We could just place the table outside the function but we might need to access
  this table within other areas of the script/even outside the script.]]
  --Finally, we just do what the client wanted us to do. After updating our current list, we can get the required referance
  if _G.ServiceData[tostring(ReferanceName)] ~= nil then --Checks if the referance exists
    table.insert(Logs,{
      EventType = "Notification";
      ResponceMessage = "Refer-Get";
      TimeRecorded = os.time();
      ReferanceName = ReferanceName;
    }) ;
    return _G.ServiceData[ReferanceName]; --Found our referance, now we return the referance.
  else
    table.insert(Logs,{
      EventType = "Error";
      ResponceMessage = "Refer-Failed";
      TimeRecorded = os.time();
      ReferanceName = ReferanceName;
    }) ;
    warn("Unable to get referance. Is the referanceinput correct?");
    return nil; -- We cannot return anything, we just return nil towards the client
  end
end

Services.FetchData = function(Player,Dataname)
  if UserData[Player.Name][Dataname] ~= nil then
    return UserData[Player.Name][Dataname]; --Simple, we just want a section of the user data. No editing, no refreshing.
    table.insert(Logs,{
      EventType = "Notification";
      ResponceMessage = "Client-Fetch-Data";
      TimeRecorded = os.time();
    });
  else
    table.insert(Logs,{
      EventType = "Error";
      ResponceMessage = "Client-Failed-Fetch";
      TimeRecorded = os.time();
    })
    warn("Failed to fetch users data! Perhaps you might need to delay the clients attempt at fetching the players data") --Just to say that the client might have asked for data too quickly after joining.
    return nil;
  end
end

Services.CreateUserData = function(Player)
  UserData[Player.Name] = {};
  if (DataEvent[Player.Name] == nil) then
    DataEvent[Player.Name] = true;
    local NewProfile = nil;
    local Success,Responce = pcall(function()
        NewProfile = ProfileDatabase:GetAsync(Player.Name);
    end)
    if (not Success) then
      print(Responce);
      table.insert({
        EventType = "Error";
        ResponceMessage = Responce;
        TimeRecorded = os.time();
      }); --This would push an error event towards the log that we created.
    elseif (Profile == {} or Profile == nil) then
      UserData[Player.Name] = DefaultData -- The player is new
      table.insert({
        EventType = "Notification";
        ResponceMessage = "New-User-Added";
        TimeRecorded = os.time();
      });
    elseif Profile then
      UserData[Player.Name] = Profile;
      table.insert({
        EventType = "Notification";
        ResponceMessage = "Data-Created";
        TimeRecorded = os.time();
      })
    end
  end
  if BindNewCycles then
    Services.ReloadData(Player);
  end
end

Services.AddData = function(Player,DataToAdd,Dataname,AmountToAdd)
  --[[You can add a feature in which would check if either the user already owns said data or the data exists within the referance. When using a referance, please
  add this feature as your data will get corrupted (client sided).
  ]]
  if AmountToAdd < 1 then return end; --A failsafe in which would prevent the use of negative numbers within dictionaries.
  if (not AmountToAdd) then AmountToAdd = 1 end; --Checks if the parameter "AmountToAdd" has a value. If not then set towards 1.
  if (UserData[Player.Name][Dataname] ~= nil) then --Would have to contain playerobject.
    if (UserData[Player.Name][Dataname]["Owned"][DataToAdd] == nil) then --Attempts to find if the item exists within the user "owned" section
      UserData[Player.Name][Dataname]["Owned"][DataToAdd] = AmountToAdd; --Creates a new instance of said item with the amount in which exists;
    elseif (UserData[Player.Name][Dataname]["Owned"][DataToAdd] >= 1) then
      UserData[Player.Name][Dataname]["Owned"][DataToAdd] += AmountToAdd; --Instance exists, add towards existing instance
    end
  end
  Services.SaveData(Player); --Would need to save after the use of adding an item. You can remove this if you dont want to save after an item is added.
  table.insert(Logs,{
    EventType = "Notification";
    ResponceMessage = "Data-Added";
    TimeRecorded = os.time();
    AddedInfo = {Player.Name,DataToAdd,Dataname,AmountToAdd}; --This would be used to track what items are added.
  })
end

Services.RemoveData = function(Player,DataToRemove,Dataname,AmountToRemove)
  --[[This feature would be similar towards the use of "Services.AddData" in which would edit the use of the userdatabase. You might need to save
  the data to keep changes. We would try and prevent the use of the data being corrupted from the use of either selecting the wrong dataname or any other factors.
  You may be able to use a pcall() to protect yourself from the process along with the two variables (Success and ErrorMessage) to determin what the error is. You can
  contact any errors with the use of the issues feature in github]]
  
  if AmountToRemove < 1 then return end; --A failsafe in which would prevent the use of negative numbers within dictionaries.
  if (not AmountToRemove) then AmountToRemove = 1 end; --Checks if the parameter "AmountToAdd" has a value. If not then set towards 1.
  if (UserData[Player.Name][Dataname] ~= nil) then --Would have to contain playerobject.
    if (UserData[Player.Name][Dataname]["Owned"][DataToRemove] > 1) then --Checks if the player has more than one of the instance. We can take it away.
      UserData[Player.Name][Dataname]["Owned"][DataToRemove] -= AmountToRemove; --Takes away the amount you wanted to take away.
    elseif (UserData[Player.Name][Dataname]["Owned"][DataToAdd] == 1) then --If there is only one of the instance
      UserData[Player.Name][Dataname]["Owned"][DataToAdd] = nil; --Takes the instance away from the dictionary using nil.
    end
  end
  Services.SaveData(Player); --Again, you would need to save the changes you made. You dont want to lose data in case of any server crashes.
  table.insert(Logs,{
    EventType = "Notification";
    ResponceMessage = "Data-Removed";
    TimeRecorded = os.time();
    RemovedInfo = {Player.Name,DataToRemove,Dataname,AmountToAdd); --Again, some infomation to help us see what data has been removed.
  })
end

Services.SaveData = function(Player)
  local ServerAttempts = 10; 
  --[[ This would the amount of attempts the server would do to try and save the users data. If the number is reached. The data will not be saved. You may
  add a notification towards the client in which tells the user that the data cannot be saved. If the configuation "SaveDataWhenAvailable" is enabled then the
  server would attempt to save the data when the roblox dataservers are available ]]
  
  spawn(function() --This would yield and complete the process of saving data. This is in case of loads of people leaving at the same time (server overload)
    if Services.DataSaved[Player.Name] == nil then
      Services.DataSaved[Player.Name] = true;
      local Success,Responce = pcall(function()
        ProfileDatabase:SetAsync(Player.UserId, UserData[Player.Name]);
      end)
      if not Success then
        local RecoverySuccess = false;
        repeat
          local Success,Responce = pcall(function()
            ProfileDatabase:SetAsync(Player.UserId, UserData[Player.Name]);
          end)
          if Success then
            RecoverySuccess = true;
          else
            ServerAttempts -= 1;
          end
          if ServerAttempts <= 0 then
            print("Server cannot save ..Player.Name.."'s data. Please try again later");
            table.insert(Logs,{
              EventType = "Error";
              ResponceMessage = Responce;
              TimeRecorded = os.time();
              --You can add a remoteevent in which would notify the user that the server cannot save the data here. (If you want)
            });
            break
          end
        until RecoverySuccess
      end
      Services.DataSaved[Player.Name] = nil;
    end
  end)
end

--Connections: We need these to contact the client/server.
ReplicatedStorage[EventName].OnServerInvoke = Service.FetchData;
ReplicatedStorage.FetchReferance.OnServerInvoke = Service.FetchReferance;

return Service;
