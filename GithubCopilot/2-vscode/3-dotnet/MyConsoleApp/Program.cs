using System;
using System.Collections.Generic;
using System.Linq;

namespace MyConsoleApp
{
    class Program
    {
        static void Main(string[] args)
        {
            List<int> numbers = new List<int> { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 };
            int sum = numbers.Sum();
            Console.WriteLine($"The sum of the numbers is: {sum}");
        }
    }
}
