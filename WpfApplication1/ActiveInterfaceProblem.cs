using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace WpfApplication1
{
    class ActiveInterfaceProblem : Exception
    {
        //problem selecting active interface, functionality must be blocked, maybe refresh button???
        public ActiveInterfaceProblem()
        {

        }

        public ActiveInterfaceProblem(string msg) : base(msg)
        {

        }

        public ActiveInterfaceProblem(string msg, Exception inner) : base(msg)
        {

        }

    }
}
