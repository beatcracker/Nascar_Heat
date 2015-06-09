#include <idc.idc>

static FloatsToCsv(csv_file)
{
    auto seg_ea, ea, image_base, csv_file_handle, csv_template, csv_header;

    csv_header = "Address, Offset, Name, Disasm, Value\n";
    csv_template = "\"0x%x\", \"0x%x\", \"%s\", \"%s\", \"%f\"\n";

    if(csv_file != 0)
    {
        // Create file handle
        csv_file_handle = fopen(csv_file, "w");
        
    }

    // Get .rdata segment
    seg_ea = SegByBase(SegByName(".rdata"));

    // Get imagebase from IDB. If there is a better way, let me know.
    image_base = xtol(substr(LineA(FirstSeg(), 2), 16, 22));

    // Print CSV header to console
    Message(csv_header);
    
    if(csv_file_handle)
    {
        // Print CSV header to file
        fprintf(csv_file_handle, csv_header);
    }

    // loop through entire .rdata segment
    for (ea = SegStart(seg_ea) ; ea != BADADDR ; ea = NextHead(ea, SegEnd(seg_ea)))
    {
        // If value has references
        if(DfirstB(ea))
        {
            // If reference type is "read"
            if(XrefType() == dr_R)
            {
                // If value type is float
                if ((GetFlags(ea) & DT_TYPE) == FF_FLOAT)
                {
                    // Print CSV to console
                    Message(csv_template, ea, (ea - image_base), Name(ea), GetDisasm(ea), GetFloat(ea));

                    if(csv_file_handle)
                    {
                         // Print CSV to file
                        fprintf(csv_file_handle, csv_template, ea, (ea - image_base), Name(ea), GetDisasm(ea), GetFloat(ea));
                    }
                }
            }
        }
    }

    if(csv_file_handle)
    {
        // Close file handle
        fclose(csv_file_handle);
    }
}

static main()
{
    auto filename;

    // If you cancel file dialog, script will only print CSV to console
    filename = AskFile (1, "Heat.csv", "Where to save resulting CSV file?");
    FloatsToCsv(filename);
}