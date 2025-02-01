using Microsoft.VisualStudio.TestTools.UnitTesting;
using System;
using Hellogithubcopilot;
using System.Collections.Generic;
namespace UnitTestwithgihubcopilot
{
    [TestClass]
    public class copilottestingvs
    {
        [TestMethod]
        public void SubsstractTwonumbersEqualsCorrect()
        {
            // Arrange
            int a = 10;
            int b = 5;
            int expected = 5;

            // Act
            int actual = Program.SubstractNumbers(a, b);

            // Assert
            Assert.AreEqual(expected, actual);


        }

        [TestMethod]
        //test the IsPrime function
        public void IsPrimeNumber()
        {
            // Arrange
            int number = 7;
            bool expected = true;

            // Act
            bool actual = Program.IsPrime(number);

            // Assert
            Assert.AreEqual(expected, actual);
        }


        [TestMethod]
        // test the sum function
        public void SumNumbers()
        {
            // Arrange
            List<int> numbers = new List<int> { 1, 2, 3, 4, 5 };
            int expected = 15;

            // Act
            int actual = Program.Sum(numbers);

            // Assert
            Assert.AreEqual(expected, actual);
        }


    }
}
