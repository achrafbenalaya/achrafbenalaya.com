using System;
using System.Collections.Generic;

namespace Hellogithubcopilot
{
    /// <summary>
    /// The main class of the application.
    /// </summary>
    public class Program
    {
        /// <summary>
        /// Sums all the numbers in a list of integers.
        /// </summary>
        /// <param name="numbers">The list of integers to sum.</param>
        /// <returns>The sum of all the numbers in the list.</returns>
        public static int Sum(List<int> numbers)
        {
            int sum = 0;
            for (int i = 0; i < numbers.Count; i++)
            {
                sum += numbers[i];
            }
            return sum;
        }

        public static int AddNumbers(int a, int b)
        {
            return a + b;
        }

        /// <summary>
        /// Determines whether a given number is a prime number.
        /// </summary>
        /// <param name="number">The number to check.</param>
        /// <returns><c>true</c> if the number is prime; otherwise, <c>false</c>.</returns>
        public static bool IsPrime(int number)
        {
            if (number <= 1)
            {
                return false;
            }
            if (number == 2)
            {
                return true;
            }
            if (number % 2 == 0)
            {
                return false;
            }
            int boundary = (int)Math.Sqrt(number);
            for (int i = 3; i <= boundary; i += 2)
            {
                if (number % i == 0)
                {
                    return false;
                }
            }
            return true;
        }

        /// <summary>
        /// The main entry point of the application.
        /// </summary>
        /// <param name="args">The command-line arguments.</param>
        static void Main(string[] args)
        {
            for (int i = 1; i <= 333; i++)
            {
                Console.WriteLine($"Hello Copilot {i}");
            }

            // Create a list of integers
            List<int> numbers = new List<int> { 1, 2, 3, 4, 5 };
            Console.WriteLine($"The sum of the numbers is: {Sum(numbers)}");

            // Check if a number is prime
            int number = 7;
            if (IsPrime(number))
            {
                Console.WriteLine($"{number} is a prime number");
            }
            else
            {
                Console.WriteLine($"{number} is not a prime number");
            }

            int result = AddNumbers(5, 3);
            Console.WriteLine($"The result is: {result}");

            // Prevent the console window from closing immediately
            Console.WriteLine("Press Enter to exit...");
            Console.ReadLine();
        }

        /// <summary>
        /// Subtracts two numbers and returns the result.
        /// </summary>
        /// <param name="a">The first number.</param>
        /// <param="b">The second number.</param>
        /// <returns>The result of subtracting b from a.</returns>
        public static int SubstractNumbers(int a, int b)
        {
            return a - b;
        }
    }
}
