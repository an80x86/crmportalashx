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
        var id = !string.IsNullOrWhiteSpace(context.Request["id"]) ? context.Request["id"] : "0";
        var tip = HttpContext.Current.Request.HttpMethod.ToLower();

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
                    var count = 0;
                    var liste = Helper.GetWebService().PortalUserList("", Helper.MIN, Helper.MAX);
                    if (!string.IsNullOrEmpty(liste.Message))
                    {
                        throw new Exception("Login işleminde hata : " + liste.Message);
                    }
                    else
                    {
                        var ret = liste.Value.KullaniciListesi.ToList();
                        if (id != "0")
                        {
                            #region put
                            if (tip == "put" && ret.Count>0)
                            {
                                var strJson = new StreamReader(context.Request.InputStream).ReadToEnd();
                                dynamic newForm = JObject.Parse(strJson);

                                var x0 = new WebReference.UserRes[1];
                                var y0 = new WebReference.UserRes()
                                {
                                    id = Helper.HasProperty(newForm,"id") ? newForm.id : 0,
                                    user_kod = newForm.user_kod,
                                    user_ad = newForm.user_ad,
                                    user_soyad = newForm.user_soyad,
                                    user_sifre = newForm.user_sifre != ret[0].user_sifre ? Helper.Md5Hash(newForm.user_sifre.ToString()) : ret[0].user_sifre,
                                    durum = Helper.HasProperty(newForm,"durum") ? newForm.durum : false
                                };
                                x0[0] = y0;
                                var z0 = Helper.GetWebService().InsertPortalUSer(x0);
                                if (!z0.Result)
                                    throw new Exception(z0.Message);
                            }
                            #endregion

                            if (id != "0" && tip == "delete")
                            {
                                var z0 = Helper.GetWebService().PortalKullaniciSil(id.ToInt());
                                if (!z0.Result)
                                    throw new Exception(z0.Message);
                            }

                            var tmp = ret.FirstOrDefault(e => e.id == id.ToInt());
                            ret = new List<UserRes>();
                            if (tmp != null) ret.Add(tmp);
                        }
                        else
                        {
                            if (tip == "post")
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
                                    durum = Helper.HasProperty(newForm,"durum") ? newForm.durum : false
                                };
                                x0[0] = y0;
                                var z0 = Helper.GetWebService().InsertPortalUSer(x0);
                                if (!z0.Result)
                                    throw new Exception(z0.Message);

                                liste = Helper.GetWebService().PortalUserList("", Helper.MIN, Helper.MAX);
                                if (!string.IsNullOrEmpty(liste.Message))
                                {
                                    throw new Exception("Login işleminde hata : " + liste.Message);
                                }

                                ret = liste.Value.KullaniciListesi.ToList().Where(x => x.user_kod == newForm.user_kod.Value)
                                    .ToList();
                            }
                            else
                            {
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
                                if (!string.IsNullOrEmpty(sort) && ret.Count > 0)
                                {
                                    var dynamicPropFromStr = typeof(UserRes).GetProperty(sort);

                                    if (order.ToLower().Equals("asc"))
                                    {
                                        ret = ret.OrderBy(x => dynamicPropFromStr.GetValue(x, null)).ToList();
                                    }
                                    else
                                    {
                                        ret = ret.OrderByDescending(x => dynamicPropFromStr.GetValue(x, null)).ToList();
                                    }
                                }

                                // substring
                                if (ret.Count > 0)
                                {
                                    count = ret.Count;
                                    var tmp = new List<UserRes>();
                                    for (var i = 0; i < limit.ToInt(); i++)
                                    {
                                        if (ret.Count > start.ToInt() + i)
                                        {
                                            tmp.Add(ret[start.ToInt() + i]);
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
                            }
                        }

                        var jsonStrx = Newtonsoft.Json.JsonConvert.SerializeObject(ret);
                        jsonStrx = "{\"count\":\"" + (ret.Count > 1 ? count.ToString() : ret.Count.ToString()) +"\",\"data\":"+jsonStrx+" }";
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