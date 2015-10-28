using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Net;
using System.Net.NetworkInformation;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;
using NETCONLib;
using Microsoft.Win32;
using System.Windows.Threading;

namespace WpfApplication1
{
 
    public partial class MainWindow : Window
    {

        #region Property
        private NetworkInterface actualInterface;
        private NetworkInterface createdWifiInterface;
        private AppState appState;
        private appStateObject appStateObj = new appStateObject();

        #endregion

        #region DTO
        private class appStateObject
        {
            public bool BtnStartNetwork;
            public bool BtnStopNetwork;
            public bool TbSsidName;
            public bool TbSsidPass;
            public AppState appStateBeforeChange;
        }

        #endregion

        #region Helper Methods
        [DllImport("Iphlpapi.dll", CharSet = CharSet.Auto)]
        public static extern int GetBestInterface(UInt32 destAddr, out UInt32 bestIfIndex);

        private void setAppInactive()
        {

            if (appState != AppState.NO_ACTIVE_INTERFACE)
            {
                Dispatcher.Invoke(DispatcherPriority.Normal, new Action<appStateObject>(obj => obj.BtnStartNetwork = btn_startNetwork.IsEnabled), appStateObj);
                Dispatcher.Invoke(DispatcherPriority.Normal, new Action<appStateObject>(obj => obj.BtnStopNetwork = btn_stopNetwork.IsEnabled), appStateObj);
                Dispatcher.Invoke(DispatcherPriority.Normal, new Action<appStateObject>(obj => obj.TbSsidName = tb_ssidName.IsEnabled), appStateObj);
                Dispatcher.Invoke(DispatcherPriority.Normal, new Action<appStateObject>(obj => obj.TbSsidPass = tb_ssidPass.IsEnabled), appStateObj);
                Dispatcher.Invoke(DispatcherPriority.Normal, new Action<appStateObject>(obj => obj.appStateBeforeChange = appState), appStateObj);
            }

            Dispatcher.Invoke(DispatcherPriority.Normal, new Action<Button>(btn => btn.IsEnabled = false), btn_startNetwork);
            Dispatcher.Invoke(DispatcherPriority.Normal, new Action<Button>(btn => btn.IsEnabled = false), btn_stopNetwork);
            Dispatcher.Invoke(DispatcherPriority.Normal, new Action<TextBox>(tb => tb.IsEnabled = false), tb_ssidName);
            Dispatcher.Invoke(DispatcherPriority.Normal, new Action<TextBox>(tb => tb.IsEnabled = false), tb_ssidPass);
            Dispatcher.Invoke(DispatcherPriority.Normal, new Action<KeyValuePair<Label, string>>(pair => pair.Key.Content = pair.Value), new KeyValuePair<Label, string>(lab_ActiveIntName, "No Active interface"));

            appState = AppState.NO_ACTIVE_INTERFACE;
        }


        private void setInterface(List<NetworkInterface> intsEthernetOrWifi, uint bestIndex)
        {
            NetworkInterface intFace = NetworkInterface.GetAllNetworkInterfaces()[bestIndex];


            if (intsEthernetOrWifi.Any<NetworkInterface>( item => item.Description == intFace.Description && item.Id == intFace.Id ))
            {
                if(appState == AppState.NO_ACTIVE_INTERFACE)
                {
                    Dispatcher.Invoke(DispatcherPriority.Normal, new Action<Button>(btn => btn.IsEnabled = appStateObj.BtnStartNetwork), btn_startNetwork);//btn_startNetwork.IsEnabled = true;
                    Dispatcher.Invoke(DispatcherPriority.Normal, new Action<Button>(btn => btn.IsEnabled = appStateObj.BtnStopNetwork), btn_stopNetwork);//btn_startNetwork.IsEnabled = true;
                    Dispatcher.Invoke(DispatcherPriority.Normal, new Action<TextBox>(tb => tb.IsEnabled = appStateObj.TbSsidName), tb_ssidName);
                    Dispatcher.Invoke(DispatcherPriority.Normal, new Action<TextBox>(tb => tb.IsEnabled = appStateObj.TbSsidPass), tb_ssidPass);

                }
                appState = AppState.ACTIVE_INTERFACE;
                actualInterface = intFace;
                Dispatcher.Invoke(DispatcherPriority.Normal, new Action<KeyValuePair<Label, string>>(pair => pair.Key.Content = pair.Value), new KeyValuePair<Label, string>(lab_ActiveIntName, actualInterface.Description.ToString()));
                
            }
            else
            {
                setAppInactive();
            }
        }

        private void checkInterfaces()
        {
            List<NetworkInterface> ethernetOrWifiWithStatusUp = new List<NetworkInterface>();

            ethernetOrWifiWithStatusUp = NetworkInterface.GetAllNetworkInterfaces().Where(item => item.OperationalStatus == OperationalStatus.Up && (item.NetworkInterfaceType == NetworkInterfaceType.Ethernet || item.NetworkInterfaceType == NetworkInterfaceType.Wireless80211)).ToList();
            
            uint publicDnsAddress = BitConverter.ToUInt32(IPAddress.Parse("4.2.2.2").GetAddressBytes(), 0);
            uint googlePubDnsAddress = BitConverter.ToUInt32(IPAddress.Parse("8.8.8.8").GetAddressBytes(), 0);


            uint bestIndex;

            if (GetBestInterface(publicDnsAddress, out bestIndex) == 0)
            {
                //no error trying 4.2.2.2
                setInterface(ethernetOrWifiWithStatusUp, bestIndex);
            }
            else if (GetBestInterface(googlePubDnsAddress, out bestIndex) == 0)
            {
                //error using 4.2.2.2, trying 8.8.8.8
                setInterface(ethernetOrWifiWithStatusUp, bestIndex);
            }
            else
            {
                //error on both IPs
                setAppInactive();
            }

        }


        private bool checkFields()
        {
            if(String.IsNullOrEmpty(tb_ssidName.Text.ToString()))
            {
                MessageBox.Show("Please, enter network name");
                return false;
            }
            if (tb_ssidName.Text.ToString().Length < 4)
            {
                MessageBox.Show("Too short network name. Minimum length is 4 characters");
                return false;
            }
            if (tb_ssidName.Text.ToString().Length > 32)
            {
                MessageBox.Show("Too long network name. Maximum length is 32 characters");
                return false;
            }
            if(String.IsNullOrEmpty(tb_ssidPass.Text.ToString()))
            {
                MessageBox.Show("Please, specify network password");
                return false;
            }
            else if (tb_ssidPass.Text.ToString().Length < 8)
            {
                MessageBox.Show("The password must be at least 8 character long");
                return false;
            }
            return true;
        }

        private string executeCommand(string command)
        {
            ProcessStartInfo startInfo = new ProcessStartInfo("cmd", "/c " + command);
            startInfo.CreateNoWindow = true;
            startInfo.UseShellExecute = false;
            startInfo.RedirectStandardOutput = true;

            Process proc = new Process();
            proc.StartInfo = startInfo;
            proc.Start();

            return proc.StandardOutput.ReadToEnd();
        }

        private void startSharing()
        {
            INetSharingManager sharinManager = new NetSharingManager();
            var list = sharinManager.EnumEveryConnection;
            var enumerator = list.GetEnumerator();
            while(enumerator.MoveNext())
            {
                var item = enumerator.Current;
                var asd = sharinManager.NetConnectionProps[ (INetConnection) item ];

                var sdf = sharinManager.get_INetSharingConfigurationForINetConnection((INetConnection) item);

                if (asd.DeviceName == actualInterface.Description)
                {
                    //sdf.DisableSharing();
                    int i = 0;
                    do
                    {
                        try
                        {
                            sdf.EnableSharing(tagSHARINGCONNECTIONTYPE.ICSSHARINGTYPE_PUBLIC);
                            break;
                        }
                        catch
                        {
                            if (i == 29)
                            {
                                MessageBox.Show("Cannot share internet. Restart application or share manually");
                            }
                            i++;
                        }
                    } while (i < 10);
                }
                
                if (asd.DeviceName == createdWifiInterface.Description)
                {
                    //sdf.DisableSharing();
                    int i = 0;
                    do{
                        try
                        {
                            sdf.EnableSharing(tagSHARINGCONNECTIONTYPE.ICSSHARINGTYPE_PRIVATE);
                            break;
                        }catch
                        {
                            if(i == 29)
                            {
                                MessageBox.Show("Cannot share internet. Restart application or share manually");
                            }
                            i++;
                        }   
                    }while(i<10);
                }
                
            }

            try
            {
                Registry.SetValue("HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Services\\ICSharing\\Settings\\General", "HangUpTimer", 10800);    //10800 - 60*60*3 2hodky
                appState = AppState.NETWORK_STARTED_AND_SHARED;
            }
            catch
            {
                MessageBox.Show("error setting registry");
                //UnauthorizedAccessException || SecurityException 
            }


        }

        private void stopSharing()
        {
            
            INetSharingManager sharinManager = new NetSharingManager();
            var list = sharinManager.EnumEveryConnection;
            var enumerator = list.GetEnumerator();
            while (enumerator.MoveNext())
            {
                var item = enumerator.Current;
                var asd = sharinManager.NetConnectionProps[(INetConnection)item];

                var sdf = sharinManager.get_INetSharingConfigurationForINetConnection((INetConnection)item);

                if (actualInterface != null && asd.DeviceName == actualInterface.Description)
                {
                    sdf.DisableSharing();
                }

                if (createdWifiInterface != null && asd.DeviceName == createdWifiInterface.Description)
                {
                    sdf.DisableSharing();
                }

            }


            
        }

        private bool checkStartedWlanNetwork()
        {
            //https://www.youtube.com/watch?v=7WfJArKyqQw   ????
            createdWifiInterface = NetworkInterface.GetAllNetworkInterfaces().FirstOrDefault(intface => intface.Description == "Microsoft Hosted Network Virtual Adapter" && intface.OperationalStatus == OperationalStatus.Up);
            if(createdWifiInterface != null)
            {
                return true;
            }
            return false;
        }

        private void startNetwork()
        {

            executeCommand("netsh wlan set hostednetwork mode=allow ssid="+ tb_ssidName.Text+" key="+tb_ssidPass.Text);
            executeCommand("netsh wlan start hostednetwork");
            if (checkStartedWlanNetwork())
            {
                appState = AppState.NETWORK_STARTED;
                startSharing();
            }
            else
            {
                appState = AppState.NETWORK_DOES_NOT_STARTED;
                MessageBox.Show("Problem in starting hostednetwork. Try update drivers and widnows and retry later.");
            }

        }
        #endregion


        #region Event Handlers
        private void click_btnStart(object sender, EventArgs e)
        {
            checkInterfaces();
            if (appState == AppState.ACTIVE_INTERFACE)
            {
                if (checkFields())
                {
                    startNetwork();
                }
            }
            if(appState == AppState.NETWORK_STARTED_AND_SHARED)
            {
                btn_startNetwork.IsEnabled = false;
                btn_stopNetwork.IsEnabled = true;
                tb_ssidName.IsEnabled = false;
                tb_ssidPass.IsEnabled = false;
            }
        }

        private void stopWlanAndSharing()
        {
            executeCommand("netsh wlan stop hostednetwork");
            stopSharing();
        }

        private void click_btnStop(object sender, EventArgs e)
        {
            stopWlanAndSharing();
            if (appState == AppState.ACTIVE_INTERFACE)
            {
                btn_startNetwork.IsEnabled = true;
                btn_stopNetwork.IsEnabled = false;
                tb_ssidName.IsEnabled = true;
                tb_ssidPass.IsEnabled = true;
            }
        }

        private void app_closing(object sender, EventArgs e)
        {
            stopWlanAndSharing();
            saveSettings();
        }

        private void AddressChangedCallback(object sender, EventArgs e)
        {
            checkInterfaces();
        }
        #endregion

        private void Application_DispatcherUnhandledException(object sender, System.Windows.Threading.DispatcherUnhandledExceptionEventArgs e)
        {
            MessageBox.Show("An unhandled exception just occurred: " + e.Exception.Message, "Exception Sample", MessageBoxButton.OK, MessageBoxImage.Warning);
            e.Handled = true;
        }


        private void loadSettings()
        {
            tb_ssidName.Text = Properties.Settings.Default.ssidName;
            tb_ssidPass.Text = Properties.Settings.Default.ssidPassword;


        }

        private void saveSettings()
        {
            Properties.Settings.Default.ssidName = tb_ssidName.Text;
            Properties.Settings.Default.ssidPassword = tb_ssidPass.Text;
            Properties.Settings.Default.Save();
        }


        public MainWindow()
        {
            
            this.ResizeMode = System.Windows.ResizeMode.NoResize;
            InitializeComponent();
            loadSettings();
            stopWlanAndSharing();
            checkInterfaces();
            NetworkChange.NetworkAddressChanged += new NetworkAddressChangedEventHandler(AddressChangedCallback);
        }
    }
}
