using System.Web.Mvc;
using GG.Web.HelloMVCWorld.Controllers;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace GG.HelloMVCWorld.Test.Unit.Controllers
{
    [NUnit.Framework.TestFixture]
    public class HomeControllerTest
    {
        [NUnit.Framework.TestCase]
        public void Index()
        {
            // Arrange
            HomeController controller = new HomeController();

            // Act
            ViewResult result = controller.Index() as ViewResult;

            // Assert
            Assert.AreEqual("Modify this template to jump-start your ASP.NET MVC application.", result.ViewBag.Message);
        }

        [NUnit.Framework.TestCase]
        public void About()
        {
            // Arrange
            HomeController controller = new HomeController();

            // Act
            ViewResult result = controller.About() as ViewResult;

            // Assert
            Assert.IsNotNull(result);
        }

        [NUnit.Framework.TestCase]
        public void Contact()
        {
            // Arrange
            HomeController controller = new HomeController();

            // Act
            ViewResult result = controller.Contact() as ViewResult;

            // Assert
            Assert.IsNotNull(result);
        }
    }
}
