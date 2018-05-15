using System;
using System.Collections.Generic;
using System.Configuration;
using System.Dynamic;
using System.IO;
using System.Linq;
using System.Net;
using System.Security.Cryptography;
using System.Text;
using System.Web;
using api.WebReference;
using Newtonsoft.Json.Linq;

namespace api
{
    public class User
    {
        private HttpContext context;

        public User(HttpContext context)
        {
            //
            // TODO: Add constructor logic here
            //
            this.context = context;
        }

        public List<UserRes> All()
        {
            var liste = Helper.GetWebService().PortalUserList("", Helper.MIN, Helper.MAX);
            if (!string.IsNullOrEmpty(liste.Message))
            {
                throw new Exception("Login işleminde hata : " + liste.Message);
            }

            var ret = liste.Value.KullaniciListesi.ToList();
            return ret;
        }

        public void Put(List<UserRes> ret)
        {
            var strJson = new StreamReader(context.Request.InputStream).ReadToEnd();
            dynamic newForm = JObject.Parse(strJson);

            var x0 = new WebReference.UserRes[1];
            var y0 = new WebReference.UserRes()
            {
                id = Helper.HasProperty(newForm, "id") ? newForm.id : 0,
                user_kod = newForm.user_kod,
                user_ad = newForm.user_ad,
                user_soyad = newForm.user_soyad,
                user_sifre = newForm.user_sifre != ret[0].user_sifre ? Helper.Md5Hash(newForm.user_sifre.ToString()) : ret[0].user_sifre,
                durum = Helper.HasProperty(newForm, "durum") ? newForm.durum : false
            };
            x0[0] = y0;
            var z0 = Helper.GetWebService().InsertPortalUSer(x0);
            if (!z0.Result)
                throw new Exception(z0.Message);
        }

        public void Delete(int id)
        {
            var z0 = Helper.GetWebService().PortalKullaniciSil(id);
            if (!z0.Result)
                throw new Exception(z0.Message);
        }

        public string Post()
        {
            var strJson = new StreamReader(context.Request.InputStream).ReadToEnd();
            dynamic newForm = JObject.Parse(strJson);

            var x0 = new WebReference.UserRes[1];
            var y0 = new WebReference.UserRes()
            {
                user_kod = newForm.user_kod,
                user_ad = newForm.user_ad,
                user_soyad = newForm.user_soyad,
                user_sifre = Helper.Md5Hash(newForm.user_sifre.ToString()),
                durum = Helper.HasProperty(newForm, "durum") ? newForm.durum : false
            };
            x0[0] = y0;
            var z0 = Helper.GetWebService().InsertPortalUSer(x0);
            if (!z0.Result)
                throw new Exception(z0.Message);

            return newForm.user_kod.Value;
        }
    }
}