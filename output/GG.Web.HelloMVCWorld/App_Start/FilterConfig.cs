using System.Web;
using System.Web.Mvc;

namespace GG.Web.HelloMVCWorld
{
    public class FilterConfig
    {
        public static void RegisterGlobalFilters(GlobalFilterCollection filters)
        {
            filters.Add(new HandleErrorAttribute());
        }
    }
}