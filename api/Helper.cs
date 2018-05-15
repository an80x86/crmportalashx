using System;
using System.Collections.Generic;
using System.Configuration;
using System.Dynamic;
using System.Linq;
using System.Net;
using System.Security.Cryptography;
using System.Text;
using System.Web;
using api.WebReference;

namespace api
{
    public static class Helper
    {
        public static int MIN = 0;
        public static int MAX = 99999;

        public static string JaponDate(this string str)
        {
            // 01.01.2018
            // 0123456789
            return str.Length == 10 ? (str.Substring(6, 4) + "-" + str.Substring(3, 2) + "-" + str.Substring(0, 2)) : str;
        }

        public static string Md5Hash(this string input)
        {
            var hash = new StringBuilder();
            var md5Provider = new MD5CryptoServiceProvider();
            var bytes = md5Provider.ComputeHash(new UTF8Encoding().GetBytes(input));

            foreach (var t in bytes)
            {
                hash.Append(t.ToString("x2"));
            }
            return hash.ToString();
        }

        public static int ToInt(this string str)
        {
            return int.Parse(str);
        }

        public static WsdlUyumCrm GetWebService()
        {
            try
            {
                var serv = new WsdlUyumCrm { CookieContainer = new CookieContainer(1000) };
                serv.UyumUserLogin(
                    ConfigurationManager.AppSettings["val1"],
                    ConfigurationManager.AppSettings["val2"],
                    ConfigurationManager.AppSettings["val3"]
                );

                return serv;
            }
            catch (Exception ex)
            {
                throw new System.ArgumentException("Uyumsoft web service'i hata verdi!", ex.Message);
            }
        }

        public static bool HasProperty(dynamic obj, string name)
        {
            Type objType = obj.GetType();

            if (objType == typeof(ExpandoObject))
            {
                return ((IDictionary<string, object>)obj).ContainsKey(name);
            }

            return objType.GetProperty(name) != null;
        }
    }
}