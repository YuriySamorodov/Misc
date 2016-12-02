
#region Enable-MouseActiveWindowTracking

$MouseActiveWindowTrackingEnabled = @{

   Path = 'HKCU:\Control Panel\Mouse\'
   Name = 'ActiveWindowTracking'
   Value = '1'

}

Set-ItemProperty @MouseActiveWindowTrackingEnabled

#endregion Enable-MouseActiveWindowTracking




#region Set-Desktop

$UserPreferencesMaskParameters = @{

    Path = 'HKCU:\Control Panel\Desktop\'
    Name = 'UserPreferencesMask'
    Value = ([byte[]](0x01,0x1E,0x07,0x80,0x12,0x00,0x00,0x00))
}

Set-ItemProperty @UserPreferencesMaskParameters



$ActiveWndTrackTimeoutParameters = @{

    Path = 'HKCU:\Control Panel\Desktop\'
    Name = 'ActiveWndTrackTimeout'
    Value = '128'
}

Set-ItemProperty @ActiveWndTrackTimeoutParameters

#endregion Set-Desktop