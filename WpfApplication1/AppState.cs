using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace WpfApplication1
{
    public enum AppState
    {
        NOT_SET, NETWORK_STARTED, NO_ACTIVE_INTERFACE, NETWORK_CHANGED, ACTIVE_INTERFACE, NETWORK_DOES_NOT_STARTED, NETWORK_STARTED_AND_SHARED
    }
}
