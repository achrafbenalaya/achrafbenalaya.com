using System;
using System.Collections.Generic;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Hellogithubcopilot;

namespace Hellogithubcopilot.Tests
{
    [TestClass]
    public class ProgramTests
    {
        [TestMethod]
        public void TestSum()
        {
            List<int> numbers = new List<int> { 1, 2, 3, 4, 5 };
            int result = Program.Sum(numbers);
            Assert.AreEqual(15, result);
        }

        [TestMethod]
        public void TestAddNumbers()
        {
            int result = Program.AddNumbers(5, 3);
            Assert.AreEqual(8, result);
        }

        [TestMethod]
        public void TestIsPrime()
        {
            Assert.IsTrue(Program.IsPrime(7));
            Assert.IsFalse(Program.IsPrime(4));
            Assert.IsFalse(Program.IsPrime(1));
            Assert.IsTrue(Program.IsPrime(2));
        }

        [TestMethod]
        public void TestSubstractNumbers()
        {
            int result = Program.SubstractNumbers(5, 3);
            Assert.AreEqual(2, result);
        }
    }
}
