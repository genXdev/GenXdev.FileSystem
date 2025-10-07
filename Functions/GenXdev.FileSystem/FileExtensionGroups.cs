// ################################################################################
// Part of PowerShell module : GenXdev.FileSystem
// Original cmdlet filename  : FileExtensionGroups.cs
// Original author           : René Vaessen / GenXdev
// Version                   : 1.296.2025
// ################################################################################
// MIT License
//
// Copyright 2021-2025 GenXdev
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
// ################################################################################



namespace GenXdev.FileSystem
{
    public static class FileGroups
    {
        public static readonly Dictionary<string, HashSet<string>> Groups =
            new Dictionary<string, HashSet<string>>(StringComparer.OrdinalIgnoreCase)
            {
                // Everyday categories
                ["Pictures"] = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            { ".jpg", ".jpeg", ".png", ".gif", ".bmp", ".tiff", ".tif", ".heic", ".webp", ".raw", ".cr2", ".nef", ".orf", ".arw" },

                ["Videos"] = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            { ".mp4", ".mkv", ".avi", ".mov", ".wmv", ".flv", ".mpeg", ".mpg", ".m4v", ".3gp", ".webm" },

                ["Music"] = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            { ".mp3", ".wav", ".flac", ".aac", ".ogg", ".wma", ".m4a", ".alac", ".aiff", ".mid", ".midi" },

                ["Documents"] = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            { ".doc", ".docx", ".odt", ".rtf", ".pdf", ".tex", ".wpd" },

                ["Spreadsheets"] = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            { ".xls", ".xlsx", ".ods", ".csv", ".tsv" },

                ["Presentations"] = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            { ".ppt", ".pptx", ".odp", ".key" },

                ["Archives"] = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            {
            ".7z", ".7z.001",
            ".xz", ".bzip2", ".gzip", ".tar", ".zip", ".zip.001",
            ".wim", ".ar", ".arj", ".cab", ".chm", ".cpio", ".cramfs",
            ".dmg", ".ext", ".fat", ".gpt", ".hfs", ".ihex", ".iso",
            ".lzh", ".lzma", ".mbr", ".msi", ".nsis", ".ntfs", ".qcow2",
            ".rar", ".rpm", ".squashfs", ".udf", ".uefi", ".vdi", ".vhd",
            ".vmdk", ".xar", ".z"
            },

                ["Installers"] = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            { ".msi", ".exe", ".apk", ".dmg", ".pkg", ".deb", ".rpm" },

                ["Executables"] = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            { ".exe", ".com", ".bin", ".app", ".out", ".elf", ".scr" },

                ["Databases"] = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            { ".db", ".sqlite", ".accdb", ".mdb", ".sql", ".dbf", ".ndf", ".ldf" },

                ["DesignFiles"] = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            { ".psd", ".ai", ".indd", ".xd", ".fig", ".sketch", ".cdr", ".dwg", ".dxf" },

                ["Ebooks"] = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            { ".epub", ".mobi", ".azw3", ".fb2", ".pdf" },

                ["Subtitles"] = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            { ".srt", ".vtt", ".sub", ".ssa", ".ass" },

                ["Fonts"] = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            { ".ttf", ".otf", ".woff", ".woff2", ".eot" },

                ["EmailFiles"] = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            { ".eml", ".msg", ".pst", ".ost", ".mbox" },

                ["3DModels"] = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            { ".obj", ".stl", ".fbx", ".blend", ".3ds", ".dae", ".ply" },

                ["GameAssets"] = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            { ".pak", ".wad", ".sav", ".dat", ".uasset", ".utx", ".bsp" },

                ["MedicalFiles"] = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            { ".dcm", ".dicom", ".nii", ".hdr", ".img" },

                ["FinancialFiles"] = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            { ".qbw", ".qbb", ".qfx", ".ofx", ".gnucash", ".xls", ".xlsx", ".csv" },

                ["LegalFiles"] = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            { ".docx", ".pdf", ".rtf", ".odt" },

                // Developer / power user categories
                ["SourceCode"] = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            { ".cs", ".java", ".py", ".cpp", ".c", ".h", ".hpp", ".js", ".ts", ".go", ".rb", ".php", ".swift", ".rs", ".kt", ".m", ".scala" },

                ["Scripts"] = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            { ".ps1", ".bat", ".cmd", ".sh", ".bash", ".zsh", ".fish", ".pl", ".awk", ".tcl" },

                ["MarkupAndData"] = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            { ".xml", ".json", ".yaml", ".yml", ".toml", ".ini", ".cfg", ".conf", ".csv", ".tsv" },

                ["Configuration"] = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            { ".ini", ".cfg", ".conf", ".properties", ".env" },

                ["Logs"] = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            { ".log", ".out", ".err", ".trace" },

                ["TextFiles"] = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            { ".txt", ".md", ".rst", ".nfo", ".asc" },

                ["WebFiles"] = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            { ".html", ".htm", ".xhtml", ".css", ".scss", ".less", ".js" },

                ["MusicLyricsAndChords"] = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            { ".chordpro", ".cho", ".crd", ".ly", ".abc" },

                ["CreativeWriting"] = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            { ".story", ".novel", ".poem", ".lyrics", ".txt", ".md" },

                ["Recipes"] = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            { ".recipe", ".cook", ".txt", ".md" },

                ["ResearchFiles"] = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            { ".bib", ".ris", ".enl", ".nbib", ".tex", ".pdf", ".csv" }
            };
    }
}