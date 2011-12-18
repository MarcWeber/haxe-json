import hxjson2.JSON;

class JSON {

  static public var esc_str = ~/([\r\n"\t])/;

  static public function encodeStrBuf(value:Dynamic, sb:StringBuf){
    if (Std.is(value, List)){

      // duplicate code:
      sb.add("[");
      var first = true;
      for (x in cast(value, List<Dynamic>)){
        if (first) first = false
        else sb.add(",");
        JSON.encodeStrBuf(value, sb);
      }
      sb.add("]");

    } else if ( Std.is(value,String )) {			
      sb.add("\"");
      sb.add( esc_str.customReplace(value, function(e){
            return switch (e.matched(1)){
                case "\n": "\\n";
                case "\r": "\\r";
                case "\"": "\\\"";
                default: throw "unexpected";
            };
      }));
      sb.add("\"");
    } else if ( Std.is(value,Float) ) {			
      // only encode numbers that finate
      sb.add(Math.isFinite(cast(value,Float)) ? value+"" : "null");
    } else if ( Std.is(value,Bool) ) {			
      // convert boolean to string easily
      sb.add(value ? "true" : "false");
    } else if ( Std.is(value,Array)) {		
      // duplicate code:
      sb.add("[");
      var first = true;
      for (x in cast(value, List<Dynamic>)){
        if (first) first = false
        else sb.add(",");
        JSON.encodeStrBuf(value, sb);
      }
      sb.add("]");
    } else if (Std.is(value,Dynamic) && value != null ) {		
      throw "TODO";
    }
  }

  static public function encode(value: Dynamic){
    var s = new StringBuf();
    JSON.encodeStrBuf(value, s);
    return s.toString();
  }

  static public var reg_str    = ~/^[ \t\r\n]*"(([^"\\]+|[\\].)*)"/;
  static public var reg_str_replace   = ~/(\\.)/;

  static public var reg_true_false_null    = ~/^[ \t\r\n]*(true|false|null)/;
  static public var reg_int    = ~/^[ \t\r\n]*(-?[0123456789]+)/;
   static public var reg_float = ~/^[ \t\r\n]*(-?(?=[1-9]|0(?!\d))\d+(\.\d+)?([eE][+-]?\d+)?)/;
  static public var reg_key    = ~/^[ \t\r\n]*([^ :\t"'\r\n:]+)/;
  static public var dict_start = ~/^[ \t\r\n]*{/;
  static public var dict_end   = ~/^[ \t\r\n]*}/;
  static public var list_start = ~/^[ \t\r\n]*\[/;
  static public var list_end   = ~/^[ \t\r\n]*]/;
  static public var list_dict_sep = ~/^[ \t\r\n]*,/;
  static public var dict_k_v_sep = ~/^[ \t\r\n]*:/;

  static public function decode(s:String): Dynamic {
    var t = {s:s};
    // s.s is updated with remaining substring
    var dec:Dynamic = function(dec:Dynamic):Dynamic{
      var s = t.s;
      if (reg_true_false_null.match(s)){
        t.s = reg_true_false_null.matchedRight();
        return switch (reg_true_false_null.matched(1)){
              case "true": true;
              case "false": false;
              case "null": null;
              default: throw "unexpected";
        }
      } else if (reg_str.match(s)){
        var inner = reg_str.matched(1);
        t.s = reg_str.matchedRight();
        return reg_str_replace.customReplace(reg_str.matched(1), function(e){
            var c = e.matched(1).charAt(1);
            return switch (c){
                case "n": "\n";
                case "r": "\r";
                case "\"": "\"";
                default: c;
            };
        });


      } else if (reg_int.match(s)){
        t.s = reg_int.matchedRight();
        return Std.parseFloat(reg_int.matched(1));

      } else if (reg_float.match(s)){
        t.s = reg_float.matchedRight();
        return Std.parseFloat(reg_float.matched(1));

      } else if (dict_start.match(s)){
        s = dict_start.matchedRight();
        var o = new Hash<Dynamic>();

        if (dict_end.match(s)){
          t.s = dict_end.matchedRight();
          return o;
        }

        while (true) {
          var key;
          if (reg_key.match(s)){
            key = reg_key.matched(1); // todo: decode string
            s = reg_key.matchedRight();
          } else {
            // strings can be keys too
            t.s = s;
            key = dec(dec);
            s = t.s;
            if (!Std.is(key,String))
              throw "JSON key expected";
          }
          if (!dict_k_v_sep.match(s))
            throw ": expected, got:"+s;
          t.s = dict_k_v_sep.matchedRight();
          var v =dec(dec);
          o.set(key,v);
          if (list_dict_sep.match(t.s)){
            s = list_dict_sep.matchedRight();
          } else break;
        }

        if (!dict_end.match(t.s))
          throw "JSON } expected";
        else {
          t.s = dict_end.matchedRight();
          return o;
        }

      } else if (list_start.match(s)){
        var l = [];

        s = list_start.matchedRight();
        if (list_end.match(s)){
          t.s = list_end.matchedRight();
          return l;
        }
        while (true) {
          t.s = s;
          var v =dec(dec);
          s = t.s;
          l.push(v);
          if (list_dict_sep.match(t.s)){
            s = list_dict_sep.matchedRight();
          } else break;
        }

        if (!list_end.match(t.s))
          throw "JSON ] expected";
        else {
          t.s = list_end.matchedRight();
          return l;
        }
      } else throw "JSON syntax error, unexpected:"+s;
      throw "unexpected"; return null;
    };
    return dec(dec);
  }

}

class Test {

  static public function bench(iterations:Int, task:Void -> Void){
    function time(){
#if (js || flash9)
    return Date.now().getTime() / 1000;
#else
    return neko.Sys.time();
#end
    }

    var start = time();
    for (i in 0...iterations){
      task();
    }
    var stop = time();
    return (stop - start) / iterations;
  }

  static function main() {

    var s = "abc def geaoeunth abc def geaoeunth abc def geaoeunth abc def geaoeunth abc def geaoeunth abc def geaoeunth abc def geaoeunth abc def geaoeunth abc def geaoeunth abc def geaoeunth abc def geaoeunth abc def geaoeunth abc def geaoeunth abc def geaoeunth abc def geaoeunth abc def geaoeunth abc def geaoeunth abc def geaoeunth abc def geaoeunth abc def geaoeunth abc def geaoeunth ";

    trace(bench(200, function(){
        for (i in 0...s.length)
          s.charAt(i);
    }));

    trace (bench(200, function(){
        for (i in 0...s.length)
          StringTools.fastCodeAt(s, i);
    }));


    var r = ~/^(.*)$/;
    trace (bench(200, function(){
          r.match(s);
          r.matched(1);
    }));


    // return;

    var test = function(s:String){
      trace(s+": "+JSON.decode(s));
    }

    var f = null;
    var f2 = null;
    var f3 = null;
    
    var s = "{}"; // I used 300 line long dict 4700 lines separated by \n


    trace(bench(1, function(){
      for (l in  s.split("\n")){
        if (l == "")
          continue;
        f = JSON.decode(l);
        }
      }
      ));


    trace(bench(1, function(){
      for (l in  s.split("\n")){
        if (l == "")
          continue;
        f2 = hxjson2.JSON.decode(l,true);
        }
        }
        ));



    #if php
    trace(bench(1, function(){
      for (l in  s.split("\n")){
        if (l == "")
          continue;
          untyped __php__("json_decode($l)");
        }
        }
        ));
    #end



    #if js
    trace(bench(1, function(){
      for (l in  s.split("\n")){
        if (l == "")
          continue;
          untyped __js__("eval(\"var f3 = \"+l+\";\")");
        }
        }
        ));
    #end

    trace('id1 :'+f.id);
    trace('id2 :'+f2.id);
    if (f3!=null)
      trace('id3 :'+f3.id);
    
    trace(f);
    trace(f2);
    trace(f3);

  }    

}
