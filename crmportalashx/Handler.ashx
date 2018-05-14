<%@ WebHandler Language="C#" Class="Handler" %>

using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Web;
using Newtonsoft.Json.Linq;
using WebReference;

public class Handler : IHttpHandler {

    public void ProcessRequest (HttpContext context)
    {
        var command = !string.IsNullOrWhiteSpace(context.Request["cmd"]) ? context.Request["cmd"] : "";
        var start = !string.IsNullOrWhiteSpace(context.Request["_start"]) ? context.Request["_start"] : "0";
        var sort = !string.IsNullOrWhiteSpace(context.Request["_sort"]) ? context.Request["_sort"] : "";
        var order = !string.IsNullOrWhiteSpace(context.Request["_order"]) ? context.Request["_order"] : "asc";
        var limit = !string.IsNullOrWhiteSpace(context.Request["_limit"]) ? context.Request["_limit"] : "10";
        var q = !string.IsNullOrWhiteSpace(context.Request["q"]) ? context.Request["q"] : "";

        context.Response.Clear();
        context.Response.ContentType = "application/json; charset=utf-8";

        switch (command)
        {
            case "dologin":
                {
                    var strJson = new StreamReader(context.Request.InputStream).ReadToEnd();
                    dynamic ret = JObject.Parse(strJson);
                    var liste = Helper.GetWebService().PortalUserList("", Helper.MIN, Helper.MAX);
                    if (!string.IsNullOrEmpty(liste.Message))
                    {
                        throw new Exception("Login işleminde hata : " + liste.Message);
                    }
                    else
                    {
                        var durum = false;
                        foreach (var kullanici in liste.Value.KullaniciListesi)
                        {
                            if (kullanici.user_kod == ret.username.Value.ToString() && kullanici.user_sifre == Helper.Md5Hash(ret.password.Value.ToString()))
                            {
                                durum = true;
                                break;
                            }
                        }

                        var jsonStrx = Newtonsoft.Json.JsonConvert.SerializeObject(durum);
                        context.Response.Write(jsonStrx);
                        context.Response.End();
                    }
                }
                break;
            case "users":
                {
                    var liste = Helper.GetWebService().PortalUserList("", Helper.MIN, Helper.MAX);
                    if (!string.IsNullOrEmpty(liste.Message))
                    {
                        throw new Exception("Login işleminde hata : " + liste.Message);
                    }
                    else
                    {
                        var ret = liste.Value.KullaniciListesi.ToList();

                        // filtre var mı?
                        if (!string.IsNullOrEmpty(q))
                        {
                            ret = ret.Where(x =>
                                x.user_kod.ToLower().Contains(q.ToLower()) ||
                                x.user_ad.ToLower().Contains(q.ToLower()) ||
                                x.user_soyad.ToLower().Contains(q.ToLower())
                                ).ToList();
                        }

                        // sıralama
                        if (!string.IsNullOrEmpty(sort) && ret.Count>0)
                        {
                            //var pi = typeof(UserRes).GetProperty(sort);    
                            //ret = ret.OrderBy(x => pi.GetValue(x, null));
                            if (order.ToLower().Equals("asc"))
                                ret = (from p in ret
                                       orderby(sort)
                                       select p).ToList();
                            else
                                ret = (from p in ret
                                       orderby(sort) descending
                                       select p).ToList();
                        }

                        // substring
                        if (ret.Count > start.ToInt())
                        {
                            var tmp = new List<UserRes>();
                            for (var i = 0; i < limit.ToInt(); i++)
                            {
                                if (ret.Count > (start.ToInt() + 1))
                                {
                                    tmp.Add(ret[start.ToInt() + 1]);
                                }
                                else
                                {
                                    break;
                                }
                            }

                            ret = tmp;
                        }
                        else
                        {
                            ret = new List<UserRes>();
                        }

                        var jsonStrx = Newtonsoft.Json.JsonConvert.SerializeObject(liste.Value.KullaniciListesi);
                        jsonStrx = "{\"count\":\""+ret.Count.ToString()+"\",\"data\":"+jsonStrx+" }";
                        context.Response.Write(jsonStrx);
                        context.Response.End();
                    }
                }
                break;
        }
    }

    public bool IsReusable {
        get {
            return false;
        }
    }

}