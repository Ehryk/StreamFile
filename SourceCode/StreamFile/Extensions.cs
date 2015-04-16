using System;

namespace StreamFile
{
    public static class StringExtensions
    {
        /// <summary>
        /// Allows case insensitive checks
        /// </summary>
        public static bool Contains(this string source, string toCheck, StringComparison comp)
        {
            return source.IndexOf(toCheck, comp) >= 0;
        }

        public static bool ContainsIgnoreCase(this string source, string toCheck, StringComparison comparison = StringComparison.OrdinalIgnoreCase)
        {
            return source.IndexOf(toCheck, comparison) >= 0;
        }

        public static bool EqualsIgnoreCase(this string source, string toCheck, StringComparison comparison = StringComparison.OrdinalIgnoreCase)
        {
            return source.Equals(toCheck, comparison);
        }

        public static int ToInt(this string s, int defaultValue = -1)
        {
            return ToNullableInt(s) ?? defaultValue;
        }
        public static int? ToNullableInt(this string s)
        {
            int i;
            return Int32.TryParse(s, out i) ? i : (int?)null;
        }

        public static long ToLong(this string s, long defaultValue = -1)
        {
            return ToNullableLong(s) ?? defaultValue;
        }
        public static long? ToNullableLong(this string s)
        {
            long l;
            return Int64.TryParse(s, out l) ? l : (long?)null;
        }

        public static decimal ToDecimal(this string o)
        {
            return ToNullableDecimal(o) ?? 0;
        }
        public static decimal? ToNullableDecimal(this string o)
        {
            decimal d;
            return Decimal.TryParse(o, out d) ? d : (decimal?)null;
        }

        public static DateTime ToDateTime(this string s)
        {
            return ToNullableDateTime(s) ?? DateTime.MinValue;
        }
        public static DateTime? ToNullableDateTime(this string s)
        {
            DateTime d;
            return DateTime.TryParse(s, out d) ? d : (DateTime?)null;
        }

        public static bool ToBoolean(this string o)
        {
            return ToNullableBoolean(o) ?? false;
        }
        public static bool? ToNullableBoolean(this string o)
        {
            bool b;
            return Boolean.TryParse(o, out b) ? b : (bool?)null;
        }
    }

    public static class ObjectExtensions
    {
        public static int ToInt(this object o, int defaultValue = -1)
        {
            return ToNullableInt(o) ?? defaultValue;
        }
        public static int? ToNullableInt(this object o)
        {
            if (o is int)
                return (int)o;

            int i;
            return Int32.TryParse(o.ToString(), out i) ? i : (int?)null;
        }

        public static long ToLong(this object o, long defaultValue = -1)
        {
            return ToNullableLong(o) ?? defaultValue;
        }
        public static long? ToNullableLong(this object o)
        {
            if (o is long)
                return (long)o;

            long l;
            return Int64.TryParse(o.ToString(), out l) ? l : (long?)null;
        }

        public static decimal ToDecimal(this object o)
        {
            return ToNullableDecimal(o) ?? 0;
        }
        public static decimal? ToNullableDecimal(this object o)
        {
            if (o is decimal)
                return (decimal)o;

            decimal d;
            return Decimal.TryParse(o.ToString(), out d) ? d : (decimal?)null;
        }

        public static DateTime ToDateTime(this object o)
        {
            return ToNullableDateTime(o) ?? DateTime.MinValue;
        }
        public static DateTime? ToNullableDateTime(this object o)
        {
            if (o is DateTime)
                return (DateTime)o;

            DateTime d;
            return DateTime.TryParse(o.ToString(), out d) ? d : (DateTime?)null;
        }

        public static bool ToBoolean(this object o)
        {
            return ToNullableBoolean(o) ?? false;
        }
        public static bool? ToNullableBoolean(this object o)
        {
            if (o is bool)
                return (bool)o;

            bool b;
            return Boolean.TryParse(o.ToString(), out b) ? b : (bool?)null;
        }
    }
}