__package__    = "machinetag"
__version__    = "1.1"
__author__     = "Aaron Straup Cope"
__url__        = "http://www.aaronland.info/python/machinetag/"
__cvsversion__ = "$Revision: 1.3 $"
__date__       = "$Date: 2007/08/28 15:38:19 $"
__copyright__  = "Copyright (c) 2007 Aaron Straup Cope. Perl Artistic License."

import re
import types

class machinetag :
    """Object methods to parse and inspect machine tags

    from machinetag import machinetag

    str_mt = "flickr:user=straup"

    mt1 = machinetag(str_mt)

    if mt1.is_machinetag() :
        print "MT1 : %s" % mt1
        print "MT1 namespace : %s" % mt1.namespace()

    mt2 = machinetag("aero", "airport", "SFO")

    if mt2.is_machinetag() :
        print "MT2 : %s" % mt2
        print "MT2 : is numeric %s" % mt2.is_numeric()

    mt3 = machinetag("temp", "celcius", 20)

    if mt3.is_machinetag() :
        print "MT3 : %s" % mt3
        print "MT3 : is numeric %s" % mt3.is_numeric()
        print "MT3 : type %s" % type(mt3.value())

    mt4 = machinetag("geo:lat=24.234")

    if mt4.is_machinetag() :
        print "MT4 : %s" % mt4
        print "MT4 : is numeric %s" % mt4.is_numeric()
        print "MT4 : type %s" % type(mt4.value())
    """

    def __init__ (self, ns_or_tagraw, pred=None, value=None) :
        """Parse a raw tag, or the component parts of machine tag and return a machine tag object"""
        self.__namespace__ = None
        self.__predicate__ = None
        self.__value__ = None
        self.__ismachinetag__ = False
        self.__isnumeric__ = False

        if pred :

            re_nspred = re.compile(r"^([a-z](?:[a-z0-9_]+))$", re.IGNORECASE)

            if re_nspred.match(ns_or_tagraw) and re_nspred.match(pred) and value :
                self.__namespace__ = ns_or_tagraw
                self.__predicate__ = pred
                self.__value__ = value
        else :

            re_tag = re.compile(r"^([a-z](?:[a-z0-9_]+))\:([a-z](?:[a-z0-9_]+))\=(.+)$", re.IGNORECASE)
            m = re_tag.findall(ns_or_tagraw)

            if m :
                self.__namespace__ = m[0][0]
                self.__predicate__ = m[0][1]
                self.__value__ = m[0][2]

        if self.__namespace__ and self.__predicate__ and self.__value__ :
            self.__ismachinetag__ = True

            valtype = type(self.__value__)

            if valtype == types.IntType or valtype == types.FloatType :
                self.__isnumeric__ = True
            else :
                re_num = re.compile(r"^-?\d+(\.\d+)?$", re.IGNORECASE)
                m = re_num.findall(self.__value__)

                if m :

                    self.__isnumeric__ = True

                    if m[0] :
                        self.__value__ = float(self.__value__)
                    else :
                        self.__value__ = int(self.__value__)

    #

    def __str__ (self) :
        """Returns the object as formatted machine tag string"""

        return self.as_string()

    #

    def __unicode__ (self) :
        """Returns the object as formatted machine tag string"""

        return self.as_string()

    #

    def is_machinetag (self) :
        """Returns true or false depending on whether or not the arguments
        passed to the constructor were able to be parsed as a machine tag"""

        return self.__ismachinetag__

    #

    def is_numeric (self) :
        """Returns true or false depending on whether or not the machine tag
        object's value is an integer or a float"""

        return self.__isnumeric__ 

    #

    def namespace (self) :
        """Returns a string containing the machine tag object's namespace"""

        return self.__namespace__

    #

    def predicate (self) :
        """Returns a string containing the machine tag object's predicate"""

        return self.__predicate__

    #

    def value (self) :
        """Returns a string -- or if the value is numeric an integer or float --
        containing the machine tag object's value"""

        return self.__value__

    #

    def as_string (self) :
        """Returns the object as formatted machine tag string"""

        if self.is_machinetag() :
            return "%s:%s=%s" % (self.namespace(), self.predicate(), self.value())

    #

    def magic_8s(self):

        ns = self.namespace()
        pred = self.predicate()
        value = self.value()

        parts = [
            '%s:' % ns,
            '%s:%s=' % (ns, pred),
            '%s:%s=%s' % (ns, pred, value),
            '=%s' % value,
            ':%s=' % pred,
            '%s=%s' % (pred, value)
            ]

        return map(self.encode_magic_8s, parts)

    def encode_magic_8s(self, str):

        str = str.replace('8', '88')
        str = str.replace(':', '8c')
        str = str.replace('=', '8e')
        str = str.replace('_', '8u')

        return str

    def decode_magic_8s(self, str):

        str = str.replace('8u', '_')
        str = str.replace('8e', '=')
        str = str.replace('8c', ':')
        str = str.replace('88', '8')

        return str

if __name__ == "__main__" :

    str_mt = "flickr:user=straup"

    mt1 = machinetag(str_mt)

    if mt1.is_machinetag() :
        print "MT1 : %s" % mt1
        print "MT1 namespace : %s" % mt1.namespace()

    mt2 = machinetag("aero", "airport", "SFO")

    if mt2.is_machinetag() :
        print "MT2 : %s" % mt2
        print "MT2 : is numeric %s" % mt2.is_numeric()

    mt3 = machinetag("temp", "celcius", 20)

    if mt3.is_machinetag() :
        print "MT3 : %s" % mt3
        print "MT3 : is numeric %s" % mt3.is_numeric()
        print "MT3 : type %s" % type(mt3.value())

    mt4 = machinetag("geo:lat=24.234")

    if mt4.is_machinetag() :
        print "MT4 : %s" % mt4
        print "MT4 : is numeric %s" % mt4.is_numeric()
        print "MT4 : type %s" % type(mt4.value())

    for p in mt1.magic_8s():
        print "lazy 8s encoded: %s decoded: %s" % (p, mt1.decode_magic_8s(p))
