#!/usr/bin/env ruby
# frozen_string_literal: true

# fetch_sources.rb
#
# Rebuilds the source cache for the NITC open-letter file without committing
# the PDFs to git. Every document is fetched from nitc.ac.in and checked
# against the SHA-256 recorded when the archive was first assembled, so a
# changed file upstream is visible instead of silent.
#
#   ruby tools/scrape/fetch_sources.rb                 # fetch what is missing
#   ruby tools/scrape/fetch_sources.rb --force         # re-fetch everything
#   ruby tools/scrape/fetch_sources.rb --verify        # check existing files only
#   ruby tools/scrape/fetch_sources.rb --list          # print the manifest
#   ruby tools/scrape/fetch_sources.rb --dest other/   # default: research/raw/sources (git-ignored)
#
# Exit status: 0 all good, 1 something failed (see the summary).

require "net/http"
require "uri"
require "digest"
require "fileutils"
require "optparse"

DOCS = [
  { file: "disclosure__Committees_Constituted.pdf", label: "View", kind: "rti", url: "https://nitc.ac.in/imgserver/uploads/attachments/Ed__2fdd48db-7315-4526-92ca-6d8800c3b238_.pdf",
    sha256: "bb1201c8d3c32b6a8af2339ac1a00f350484bdad090627a7d9fa4920f894161f", bytes: 2476435, pages: 23 },
  { file: "disclosure__Suo_Motu_Disclosure.pdf", label: "View", kind: "rti", url: "https://nitc.ac.in/imgserver/uploads/attachments/Ed__21dd276e-9ba4-4e00-814c-12d728326370_.pdf",
    sha256: "b27705f917b52db52f1887abbdf38bd8b3034b2bdc4974ec8f2a96d77ad0a60e", bytes: 957231, pages: 16 },
  { file: "disclosure__Telephone_Directory.pdf", label: "Telephone Directory", kind: "rti", url: "https://nitc.ac.in/imgserver/uploads/attachments/telephone-directory-_4ee69fdf-cd9c-45aa-8131-cefc6ac5e307_0.pdf",
    sha256: "88520e5d157bc35301e61fa001e31a35cc92bae60a77bf5f81b7fc9731e7503f", bytes: 564473, pages: 30 },
  { file: "disclosure__Basic_Pay_of_Faculty.pdf", label: "Basic Pay of Faculty", kind: "rti", url: "https://nitc.ac.in/imgserver/uploads/attachments/Ed__58ceda12-6fc9-49d4-a726-2a0f1cbdc6fe_.pdf",
    sha256: "5e96abe45189e3c7b4f73856e7fd47f5b1392b75097d88c618edc5b342697517", bytes: 84854, pages: 16 },
  { file: "disclosure__Basic_Pay_of_Non_Faculty.pdf", label: "Basic Pay of Non-Faculty", kind: "rti", url: "https://nitc.ac.in/imgserver/uploads/attachments/Ed__c3869b89-1a2a-4307-8847-a9cf605481cf_.pdf",
    sha256: "304a35a1b2b7a826343899bf4aedec82780968209d9db14e463a05deca9a069f", bytes: 151382, pages: 10 },
  { file: "disclosure__Transfer_Orders.pdf", label: "Transfer Orders", kind: "rti", url: "https://nitc.ac.in/imgserver/uploads/attachments/Ed__a7331980-8fb5-48c9-97cf-f7e1b350c4ab_.pdf",
    sha256: "b7d11d9b4cb00c888d8aa38032d12d9d2e7a754a6147e2b185cf3aecf3f19d36", bytes: 24465524, pages: 17 },
  { file: "disclosure__Transfer_Orders_of_Assistant_Registrar.pdf", label: "Transfer Orders of Assistant Registrar", kind: "rti", url: "https://nitc.ac.in/imgserver/uploads/attachments/Ed__14d00fd8-198c-4d63-8b3c-a18eecb980b9_.pdf",
    sha256: "ddbcfd01cc81fd83071b963185e60297dafb1a112e20cc7572b386601394519c", bytes: 193865, pages: 1 },
  { file: "quarterly__1st_Quarter_April_June_2026_27.pdf", label: "1st Quarter (April-June) 2026-27", kind: "rti", url: "https://nitc.ac.in/imgserver/uploads/attachments/Ed__4cda7f75-c280-4c35-9d68-53ebef7be4e3_.pdf",
    sha256: "b93fe91ad7f1229857e06b4d0343e031d7625d4416edd81a6f96d76b74146adc", bytes: 406239, pages: 3 },
  { file: "quarterly__Audit_Report_National_Institute_of_Technology_Calicut_25_26.pdf", label: "Audit Report -National Institute of Technology Calicut 25-26", kind: "rti", url: "https://nitc.ac.in/imgserver/uploads/attachments/Ed__2dda3dba-16d1-4e6d-aa9d-2d9bbe1b7a52_.pdf",
    sha256: "d5f17b4f98d742b0be53d9351c2884a72279811204c90e1c3e1c39bf29126b5c", bytes: 68723, pages: 19 },
  { file: "quarterly__Summary_Report_National_Institute_of_Technology_Calicut_25_2.pdf", label: "RTI Summary Report 2025-26", kind: "rti", url: "https://nitc.ac.in/imgserver/uploads/attachments/Ed__40d1244b-310d-45a8-b264-a65d9295c766_.pdf",
    sha256: "533cbf1645bc22fa4519aeb88bdcfae7f13ca3cb24cbe4e6ec80c7ab63aece7d", bytes: 346039, pages: 2 },
  { file: "quarterly__4th_Quarter_Jan_Mar_2025_2026.pdf", label: "4th Quarter (Jan-Mar)2025-2026", kind: "rti", url: "https://nitc.ac.in/imgserver/uploads/attachments/Ed__22ddc3fd-c8a1-4945-b655-5f5640257cce_.pdf",
    sha256: "517005e38421267212dd56fab3a70ae89417c3011e5dd5bfd770dbfdf6e9fe42", bytes: 101818, pages: 2 },
  { file: "quarterly__3rd_Quarter_Oct_Dec_2025_2026.pdf", label: "3rd Quarter (Oct-Dec)2025-2026", kind: "rti", url: "https://nitc.ac.in/imgserver/uploads/attachments/Ed__73d2f5fe-d278-44d0-9dcf-e17fc4898763_.pdf",
    sha256: "caf7369b128747faed25fc5057745a65b09159738a0f9f5d41858aa2f1b338f7", bytes: 100742, pages: 2 },
  { file: "quarterly__2nd_Quarter_July_Sept_2025_2026.pdf", label: "2nd Quarter (July-Sept)2025-2026", kind: "rti", url: "https://nitc.ac.in/imgserver/uploads/attachments/Ed__983f1359-efb2-4ab7-92e1-ce6ea07cb694_.pdf",
    sha256: "171771f1be07da5ad0e2393b601fdbd95c0b320f4814dc7e3cc5ab2df9f4b3f5", bytes: 101420, pages: 2 },
  { file: "quarterly__1st_Quarter_April_June_2025_2026.pdf", label: "1st Quarter (April-June)2025-2026", kind: "rti", url: "https://nitc.ac.in/imgserver/uploads/attachments/Ed__a8a4e11c-c8d7-4dce-b1d1-ed7e723e0ef9_.pdf",
    sha256: "f51afe16b9b40e70abc5817d1a9e630873bdb2c18201bd3ad35ab39d62b80eeb", bytes: 101217, pages: 2 },
  { file: "quarterly__Audit_Report_National_Institute_of_Technology_Calicut_24_25.pdf", label: "Audit Report -National Institute of Technology Calicut 24-25", kind: "rti", url: "https://nitc.ac.in/imgserver/uploads/attachments/Ed__d44eb1b4-80f7-4f2e-b4b5-c549c4c50bab_.pdf",
    sha256: "2057ec51cdd8fe79a66c51db359e3ee6f88e75f10ba8b958a86d25dff849dfb7", bytes: 69509, pages: 21 },
  { file: "quarterly__Summary_Report_National_Institute_of_Technology_Calicut_24_2.pdf", label: "RTI Summary Report 2024-25", kind: "rti", url: "https://nitc.ac.in/imgserver/uploads/attachments/Ed__dd5d38cd-80d6-4a3b-9a8e-9deef8e23566_.pdf",
    sha256: "02c2809bb4d3a928de9b1a1942ab09d4aae9454a79e5fdb18d7a824a14e87252", bytes: 210530, pages: 2 },
  { file: "quarterly__4th_Quarter_Jan_Mar_2024_2025.pdf", label: "4th Quarter (Jan-Mar)2024-2025", kind: "rti", url: "https://nitc.ac.in/imgserver/uploads/attachments/Ed__a3689dfa-ddba-4ae5-bf8c-c13c98044d44_.pdf",
    sha256: "61c1f601bf4f6b73405291dc3d34f3e94dcff48407b9320543a59d85fa3aa394", bytes: 99706, pages: 1 },
  { file: "quarterly__3rd_Quarter_Oct_Dec_2024_2025.pdf", label: "3rd Quarter (Oct-Dec) 2024-2025", kind: "rti", url: "https://nitc.ac.in/imgserver/uploads/attachments/Ed__0a27b351-9b73-493a-888d-99b7750b2691_.pdf",
    sha256: "056e909e9cb77cfa2a356f1e2835c74a135865d38ee8846be99b0b3f7474fe68", bytes: 99970, pages: 1 },
  { file: "quarterly__2nd_Quarter_July_Sept_2024_2025.pdf", label: "2nd Quarter (July-Sept) 2024-2025", kind: "rti", url: "https://nitc.ac.in/imgserver/uploads/attachments/Ed__00960c26-c51a-485d-a514-46074abe5591_.pdf",
    sha256: "292ac433eaf8de7440d37069143b0374eb27b26c67a44bbd3c0d0a7046320236", bytes: 115088, pages: 2 },
  { file: "quarterly__Third_Party_RTI_Audit_Summary_Report_2023_2024.pdf", label: "Third Party RTI Audit Summary Report 2023-2024", kind: "rti", url: "https://nitc.ac.in/imgserver/uploads/attachments/Ed__57c7888c-ec02-41dc-bde6-cda4613c2b99_.pdf",
    sha256: "35333f138feb0a177500a488e10a1949bc9717c15fb8ed77272556df44e51431", bytes: 227279, pages: 2 },
  { file: "quarterly__Third_Party_RTI_Audit_Report_2023_2024.pdf", label: "Third Party RTI Audit Report 2023-2024", kind: "rti", url: "https://nitc.ac.in/imgserver/uploads/attachments/Ed__c62e26e5-8134-48d7-8596-30300dd025b6_.pdf",
    sha256: "84a1965b47ba06da6d6d00b15675b46075b294426ce0a75bef40e8c1f8d1d4f2", bytes: 85196, pages: 28 },
  { file: "quarterly__1st_Quarter_April_June_2024_2025.pdf", label: "1st Quarter (April-June) 2024-2025", kind: "rti", url: "https://nitc.ac.in/imgserver/uploads/attachments/Ed__584da923-0edd-4acf-a825-729a5c15d779_.pdf",
    sha256: "7e6a876024943bc8e6a5e6b9a334bb1a355806b58ed5a7a1a6d4c66d8ca7a9f2", bytes: 113960, pages: 1 },
  { file: "quarterly__4th_Quarter_Jan_Mar_2023_2024.pdf", label: "4th Quarter (Jan-Mar) 2023-2024", kind: "rti", url: "https://nitc.ac.in/imgserver/uploads/attachments/Ed__cd4e5c16-3984-43b9-9f04-ad22b80e6a5f_.pdf",
    sha256: "662b62f0718de7fb94823c440041e46a81fe062c314edd8ea5c49f8decd7c5cc", bytes: 114275, pages: 1 },
  { file: "quarterly__3rd_Quarter_Oct_Dec_2023_2024.pdf", label: "3rd Quarter (Oct-Dec) 2023-2024", kind: "rti", url: "https://nitc.ac.in/imgserver/uploads/attachments/Ed__2d144d95-d3f1-4b0b-9a95-ee2c18553a3e_.pdf",
    sha256: "debf20556cbc375cadc607f12d4a536400391b1b44c8d833f3d9c82db1d13924", bytes: 231469, pages: 2 },
  { file: "quarterly__2rd_Quarter_July_Sept_2023_2024.pdf", label: "2rd Quarter (July-Sept) 2023-2024", kind: "rti", url: "https://nitc.ac.in/imgserver/uploads/attachments/Ed__72d481a0-efcc-4eab-a414-f5dc1e2395a7_.pdf",
    sha256: "328ec7dbcf7c9f88bd75e1f700749a3261260a4571df1bca35e438c40709049f", bytes: 228438, pages: 2 },
  { file: "quarterly__1st_Quarter_April_June_2023_2024.pdf", label: "1st Quarter (April-June) 2023-2024", kind: "rti", url: "https://nitc.ac.in/imgserver/uploads/attachments/Ed__dbb2bf83-6f40-4124-b75e-8a4614b15210_.pdf",
    sha256: "faebb4c121f69e011fda1f3419c6a1455930a467772c45b36f0c6f71684c40e2", bytes: 230069, pages: 2 },
  { file: "quarterly__4th_Quarter_Jan_Mar_2022_2023.pdf", label: "4th Quarter (Jan-Mar) 2022-2023", kind: "rti", url: "https://nitc.ac.in/imgserver/uploads/attachments/Ed__51c377a9-a278-4b05-b2b9-a206eb254ee4_.pdf",
    sha256: "747340e7a8ba779268213a2db112d23493d8954cd50ec2b33db61d94c0b6e2a2", bytes: 228931, pages: 2 },
  { file: "quarterly__3rd_Quarter_Oct_Dec_2022_2023.pdf", label: "3rd Quarter (Oct-Dec) 2022-2023", kind: "rti", url: "https://nitc.ac.in/imgserver/uploads/attachments/Ed__acdbea28-f7cf-49da-9058-f97dea3470f9_.pdf",
    sha256: "1dc277c2f91fc947fc06fb3c6ffbf0ffdd29edd218e2702ce1e343019837f61f", bytes: 228699, pages: 2 },
  { file: "quarterly__Third_Party_RTI_Audit_Summary_Report_2022_2023.pdf", label: "Third Party RTI Audit Summary Report 2022-2023", kind: "rti", url: "https://nitc.ac.in/imgserver/uploads/attachments/Ed__7c4fe7c3-7922-4b23-98c9-e58522af980d_.pdf",
    sha256: "422a2580b30d969f2909bc81802c34c9409f76e8ad296a7748010a9150153e9f", bytes: 269738, pages: 24 },
  { file: "quarterly__Jul_Sep_2022_23.pdf", label: "Jul-Sep (2022-23)", kind: "rti", url: "https://nitc.ac.in/imgserver/uploads/attachments/Ed__d204f4ea-7887-4467-bcac-97d6c3dd26ca_.pdf",
    sha256: "c4e709fbf7701581601b763ac4e31936611393725592740a95524f15b38f4da1", bytes: 374828, pages: 2 },
  { file: "quarterly__Apr_Jun_2022_23.pdf", label: "Apr-Jun (2022-23)", kind: "rti", url: "https://nitc.ac.in/imgserver/uploads/attachments/Ed__7950f26c-7a4c-411d-b875-5f3e64d3fb8d_.pdf",
    sha256: "922c0bf475dec492dabf05a374ddddf368a1b37ab07e305eff6246082102fac2", bytes: 374674, pages: 2 },
  { file: "quarterly__Jan_Mar_2021_22.pdf", label: "Jan-Mar (2021-22)", kind: "rti", url: "https://nitc.ac.in/imgserver/uploads/attachments/Ed__8c699594-094b-4091-a26a-b1533e7c0008_.pdf",
    sha256: "0601d4379beffd13daceee2284fd0b0505d5dcbbaad49482d41483f93395f75a", bytes: 374819, pages: 2 },
  { file: "quarterly__Oct_Dec_2021_22.pdf", label: "Oct-Dec (2021-22)", kind: "rti", url: "https://nitc.ac.in/imgserver/uploads/attachments/Ed__98d705f6-ee99-4d09-97dd-ee9f0d5d27a0_.pdf",
    sha256: "1e373ed96b2a32e8e027354b8b3920b5328968e4fc8a7354bb2e73bdc7f0dd92", bytes: 373348, pages: 2 },
  { file: "quarterly__Jul_Sep_2021_22.pdf", label: "Jul-Sep (2021-22)", kind: "rti", url: "https://nitc.ac.in/imgserver/uploads/attachments/Ed__97ee5353-aa9d-412f-8d11-882818224d95_.pdf",
    sha256: "fc3dfe081fbc5b260704493409ac1dbe49ca00608d7c48b31fbb19a3457e1a1d", bytes: 374775, pages: 2 },
  { file: "quarterly__Apr_Jun_2021_22.pdf", label: "Apr-Jun (2021-22)", kind: "rti", url: "https://nitc.ac.in/imgserver/uploads/attachments/Ed__d277cee1-af5e-4c6b-8175-46e1fe42f2df_.pdf",
    sha256: "f789f2170d3e0bddc52febd5b42cf080d3b9aa967bb6c6239637c38b82662233", bytes: 375631, pages: 2 },
  { file: "acts__adjunct_professor_visiting_professor_professor_of_practice_e.pdf", label: "Adjunct / Visiting Professor and Professor of Practice rules", kind: "rti", url: "https://nitc.ac.in/imgserver/uploads/attachments/adjunct-professor--visiting-professor--professor-of-practice_ec5053a6-c182-42be-8521-b16d24a2a58e_0.pdf",
    sha256: "90786277404489041bcd01ae5a6a3eecda1d0c37af66298412b18ff2128be35f", bytes: 828457, pages: 2 },
  { file: "acts__first_statutes_amendment_965948b5_805b_4a8f_a04a_43a11853b21.pdf", label: "first-statutes---amendment_965948b5-805b-4a8f-a04a-43a11853b21a_0.pdf", kind: "rti", url: "https://nitc.ac.in/imgserver/uploads/attachments/first-statutes---amendment_965948b5-805b-4a8f-a04a-43a11853b21a_0.pdf",
    sha256: "dcd19fb9ac058473e0836dd7ea9340d3b678c6aee839512c4d9669579f7a811c", bytes: 1378008, pages: 16 },
  { file: "acts__nit_act_2007_667c096b_34ea_415e_8354_8ca919c568d5_0_pdf.pdf", label: "nit-act-2007_667c096b-34ea-415e-8354-8ca919c568d5_0.pdf", kind: "rti", url: "https://nitc.ac.in/imgserver/uploads/attachments/nit-act-2007_667c096b-34ea-415e-8354-8ca919c568d5_0.pdf",
    sha256: "7d3d8284f22605c1e455952dc55683845352a9c09afba0cdc76e1eb115f2e8a3", bytes: 377850, pages: 12 },
  { file: "acts__nit_act_2012_amendment_432e6c0a_8df3_41f2_ad6c_b83174094cd8_.pdf", label: "nit-act-2012-amendment_432e6c0a-8df3-41f2-ad6c-b83174094cd8_0.pdf", kind: "rti", url: "https://nitc.ac.in/imgserver/uploads/attachments/nit-act-2012-amendment_432e6c0a-8df3-41f2-ad6c-b83174094cd8_0.pdf",
    sha256: "ae82f95ca97051b2d139e16d1ad258f3287c45d8e72b847f0edb32d127b81f8b", bytes: 304424, pages: 5 },
  { file: "acts__nit_act_2012_c49144de_236a_4829_8ce9_6ffdaaf2d691_0_pdf.pdf", label: "nit-act-2012_c49144de-236a-4829-8ce9-6ffdaaf2d691_0.pdf", kind: "rti", url: "https://nitc.ac.in/imgserver/uploads/attachments/nit-act-2012_c49144de-236a-4829-8ce9-6ffdaaf2d691_0.pdf",
    sha256: "d4985bc8a290607a987f3caaca020ce1c40ddfe691b14109a18978bec9b2e9b0", bytes: 248358, pages: 13 },
  { file: "acts__nit_statutes_a225358c_d17c_4e14_9743_b0fb657c9e82_0_pdf.pdf", label: "nit-statutes_a225358c-d17c-4e14-9743-b0fb657c9e82_0.pdf", kind: "rti", url: "https://nitc.ac.in/imgserver/uploads/attachments/nit-statutes_a225358c-d17c-4e14-9743-b0fb657c9e82_0.pdf",
    sha256: "2379f24c2e549e74ff28ce128c4e361380d94add1ee483f79f4c57ce64b96577", bytes: 1859396, pages: 44 },
  { file: "acts__students_conduct_and_disciplinary_code_2025_1248_0_pdf.pdf", label: "students-conduct-and-disciplinary-code-2025_1248_0.pdf", kind: "rti", url: "https://nitc.ac.in/imgserver/uploads/attachments/students-conduct-and-disciplinary-code-2025_1248_0.pdf",
    sha256: "2e3c278447f478c8544f06b0163109c68f637616feb3290ac7e2116e8796ad06", bytes: 10334241, pages: 21 },
  { file: "acts__swagatham_2025_ug_brochure_0fd7efbb_a23a_4692_939d_80f871d6d.pdf", label: "swagatham-2025--ug-brochure_0fd7efbb-a23a-4692-939d-80f871d6d5a3_0.pdf", kind: "rti", url: "https://nitc.ac.in/imgserver/uploads/attachments/swagatham-2025--ug-brochure_0fd7efbb-a23a-4692-939d-80f871d6d5a3_0.pdf",
    sha256: "42ea4d61e5942b2c7ed95463c35fe561948642680dbd4d5f14852f6e2ef98e79", bytes: 8404324, pages: 86 },
  { file: "bog__Special_Combined_Meeting_of_the_68th_FC_77th_BoG_held_on_14_05_2026.pdf", label: "Special Combined Meeting of the 68th FC & 77th BoG held on 14/05/2026", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/special-combined-meeting-of-the-68th-fc--77th-bog-held-on-14052026_89789324-4b7a-4e42-985c-d4ad1b5490ba_0.pdf",
    sha256: "d619891965b090fa111427c8585ea8825ded447277a59bf168f1b9720bae5690", bytes: 528590, pages: 8 },
  { file: "bog__Minutes_of_the_76th_BoG_Meeting_held_on_17_04_2026.pdf", label: "Minutes of the 76th BoG Meeting held on 17/04/2026", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-76th-bog-meeting-held-on-17042026_53650260-5455-44da-bbb7-cb0743b449ff_0.pdf",
    sha256: "495438176e9d86cc37a93355cbfbe4606956e846a8878da52cbedaccc081deac", bytes: 1446552, pages: 47 },
  { file: "bog__Special_Combined_Meeting_of_the_66th_FC_75th_BoG_held_on_11_02_2026.pdf", label: "Special Combined Meeting of the 66th FC & 75th BoG held on 11/02/2026", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/special-combined-meeting-of-the-66th-fc--75th-bog-held-on-11022026_d6206fb2-193e-470e-99b4-1528b8382d78_0.pdf",
    sha256: "2bcc0e1e7def7ffcc5ddc8610841091c9353f8d5e9cfb1400a1828bd060f378a", bytes: 1941277, pages: 9 },
  { file: "bog__Minutes_of_the_73rd_BoG_Meeting_Held_on_28_03_2025.pdf", label: "Minutes of the 73rd BoG Meeting Held on 28/03/2025", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-73rd-bog-meeting-held-on-28032025_288_0.pdf",
    sha256: "402e39b4bb824986e7f46d400c451e399cc7f7e58a7c92c2381d909327d2044a", bytes: 1324333, pages: 54 },
  { file: "bog__Minutes_of_the_72nd_Special_BoG_Meeting_Held_on_13_03_2025.pdf", label: "Minutes of the 72nd Special BoG Meeting Held on 13/03/2025", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/--minutes-of-the-72nd-special-bog-meeting-held-on-13032025_287_0.pdf",
    sha256: "b583c378e385740c48fd0f639cca4c5645e4527361465cc19a66bdc55213e9f1", bytes: 3420211, pages: 11 },
  { file: "bog__Minutes_of_the_71st_BoG_Meeting_Held_on_11_12_2024.pdf", label: "Minutes of the 71st BoG Meeting Held on 11/12/2024", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-71st-bog-meeting-held-on-11122024_91fec0dc-b697-4464-8e11-7043be593bb6_0.pdf",
    sha256: "c123ee92083b57106d43b3b747b12e380528e1681bbda69b9ac2a1be4c2ac172", bytes: 793196, pages: 50 },
  { file: "bog__Minutes_of_the_70th_BoG_Meeting_Held_on_04_09_2024.pdf", label: "Minutes of the 70th BoG Meeting Held on 04/09/2024", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-70th-bog-meeting-held-on-04092024_256_0.pdf",
    sha256: "8b62530551f15466836c462f1f772981141c92a329e05826220faafb89d428a0", bytes: 3511455, pages: 51 },
  { file: "bog__Minutes_of_the_69th_BoG_Meeting_Held_on_08_07_2024.pdf", label: "Minutes of the 69th BoG Meeting Held on 08/07/2024", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-69th-bog-meeting-held-on-08072024_108c7b03-0a64-4b0b-8cb7-4ffce6be1e0f_0.pdf",
    sha256: "1304aabb80b1132f7c2abc110b367a6ba1ce4b6687ec3d451ace7c11d0d361a1", bytes: 1417253, pages: 33 },
  { file: "bog__Minutes_of_the_68th_BoG_Meeting_Held_on_15_05_2024.pdf", label: "Minutes of the 68th BoG Meeting Held on 15/05/2024", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-68th-bog-meeting-held-on-15052024_ccd499b9-b35a-4d16-a541-f92501065cf5_0.pdf",
    sha256: "aa1e3aa6d80dfea18625bf5b96f04621adb380328463a9b9ddf4e9baff2514d8", bytes: 1745097, pages: 55 },
  { file: "bog__Minutes_of_the_67th_BoG_Meeting_Held_on_22_12_2023.pdf", label: "Minutes of the 67th BoG Meeting Held on 22/12/2023", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-67th-bog-meeting-held-on-22122023_93edabbc-f806-4e68-a06f-e028a8b4414b_0.pdf",
    sha256: "f5c8e66303ec388354f5b71b250b2136c8b20e2629a5bbab58a60108125143fc", bytes: 1464764, pages: 33 },
  { file: "bog__Minutes_of_the_66th_BoG_Meeting_Held_on_01_09_2023.pdf", label: "Minutes of the 66th BoG Meeting Held on 01/09/2023", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-66th-bog-meeting-held-on-01092023_ebe57a52-6a0b-49a4-8545-2c2e0a31fa6e_0.pdf",
    sha256: "ebb3af95d6cdafa4a6332c8135afd9cd2b1095e81d235a1123285e101ab50906", bytes: 1912778, pages: 33 },
  { file: "bog__Minutes_of_the_65th_BoG_Meeting_Held_on_03_07_2023.pdf", label: "Minutes of the 65th BoG Meeting Held on 03/07/2023", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-65th-bog-meeting-held-on-03072023_197_0.pdf",
    sha256: "5a065c5cb6868af91cd796eb8aaa47fe33486924b681e16607459cf1e8f689af", bytes: 928991, pages: 49 },
  { file: "bog__Minutes_of_the_64th_BoG_Meeting_Held_on_27_02_2023.pdf", label: "Minutes of the 64th BoG Meeting Held on 27/02/2023", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-64th-bog-meeting-held-on-27022023_0b312a46-8217-4443-bad7-2f2e1b3aa9de_0.pdf",
    sha256: "7582382b9726e6df51fc2f920e46135785601c8f94080b3b223f40d157916dd4", bytes: 690433, pages: 23 },
  { file: "bog__Minutes_of_the_63rd_BoG_Meeting_Held_on_05_12_2022.pdf", label: "Minutes of the 63rd BoG Meeting Held on 05/12/2022", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-63rd-bog-meeting-held-on-05122023_f0bdecde-8eea-46a0-8d0a-8836c9a3ae44_0.pdf",
    sha256: "aa21f76247d69bc6b12497f681ca9cf075fb16df49d64b6fdb1e9248f367e990", bytes: 2353669, pages: 56 },
  { file: "bog__Minutes_of_the_62nd_BoG_Meeting_Held_on_02_09_2022.pdf", label: "Minutes of the 62nd BoG Meeting Held on 02/09/2022", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-62nd--bog-meeting-held-on-02092022_30bd3dd2-c872-43e3-bb23-1b7091064f85_0.pdf",
    sha256: "2be8123ed0527bc07c8a3534a5d21a7bd0b1aff04092ff9f566c60345e90739d", bytes: 735782, pages: 16 },
  { file: "bog__Minutes_of_the_61st_BoG_Meeting_Held_on_02_07_2022.pdf", label: "Minutes of the 61st BoG Meeting Held on 02/07/2022", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/-minutes-of-the-61st-meeting-of-the-bog-held-on-02072022_cfd346f2-ff74-40f4-b9c6-454970af4444_0.pdf",
    sha256: "103be9f77b8da8f5ce50ead37dd24a7153922b66fb5161dba4d97c74e6039449", bytes: 1127673, pages: 22 },
  { file: "bog__Minutes_of_the_60th_BoG_Meeting_Held_on_07_02_2022.pdf", label: "Minutes of the 60th BoG Meeting Held on 07/02/2022", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-60th-bog-meeting-held-on-07022022_8cb40aaa-61ec-4b26-8ba3-8d6f611c16e2_0.pdf",
    sha256: "a97ee489334210977a82bb97499f080359e744d456c71799b5b74b1eb88f75aa", bytes: 612496, pages: 28 },
  { file: "bog__Minutes_of_the_59th_BoG_Meeting_Held_on_27_10_2021.pdf", label: "Minutes of the 59th BoG Meeting Held on 27/10/2021", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-59th-bog-meeting-held-on-27102021_6027a5b6-45dd-4c16-a93a-4afca9eb4b61_0.pdf",
    sha256: "8bccaf19242b133ac9807c232799545a74cce60732e69bf25a9f1ca1f0da3656", bytes: 474563, pages: 4 },
  { file: "bog__Minutes_of_the_58th_BoG_Meeting_Held_on_25_08_2021.pdf", label: "Minutes of the 58th BoG Meeting Held on 25/08/2021", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/-minutes-of-the-58th-bog-meeting-held-on-25082021_48caa59b-d0ed-4df3-a2a5-991f70a0d73d_0.pdf",
    sha256: "204f91220da66618b99d52b23d39b1b1de2c07dd8cc6783361549ad35c9f66a3", bytes: 521494, pages: 3 },
  { file: "bog__Minutes_of_the_57th_BoG_Meeting_Held_on_01_07_2021.pdf", label: "Minutes of the 57th BoG Meeting Held on 01/07/2021", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/-minutes-of-the-57-th-bog-meeting-held-on-01072021_6c562fa7-a093-46ae-ad39-bd5f4c35c5ff_0.pdf",
    sha256: "f21e2bb7569ba60d8d9394f15fd2f8540e12c10f402cfd2538b2b9c0ea7525ad", bytes: 398843, pages: 2 },
  { file: "bog__Minutes_of_the_56th_BoG_Meeting_Held_on_14_06_2021.pdf", label: "Minutes of the 56th BoG Meeting Held on 14/06/2021", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/-minutes-of-the-56-th-bog-meeting-held-on-14062021_75aa1b39-d67f-42f4-b7bc-bf500a6369cc_0.pdf",
    sha256: "25120c98c71bb1047e9eeef9ab715c693cba848de0db8a8d1e900c99d02e259f", bytes: 390989, pages: 7 },
  { file: "bog__Minutes_of_the_55th_BoG_Meeting_Held_on_06_01_2021.pdf", label: "Minutes of the 55th BoG Meeting Held on 06/01/2021", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/-minutes-of-the-55-th-bog-meeting-held-on-06012021_479508b7-1ff6-4719-8129-d122bfa70afb_0.pdf",
    sha256: "58cb40db0102f919113533188543309c6d304b1047602e958a5129ef1b1563b7", bytes: 1065862, pages: 19 },
  { file: "bog__Minutes_of_the_54th_BoG_Meeting_Held_on_27_11_2020.pdf", label: "Minutes of the 54th BoG Meeting Held on 27/11/2020", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/-minutes-of-the-54th-bog-dated-27th-november-2020_8d326631-7e39-4895-809b-0cbd79e73c54_0.pdf",
    sha256: "a5244b74334e58f074e8ac2c6feb176fb11cf97133ab0fe569cf6eba9f820711", bytes: 342158, pages: 3 },
  { file: "bog__Minutes_of_the_53rd_BoG_Meeting_Held_on_30_06_2020.pdf", label: "Minutes of the 53rd BoG Meeting Held on 30/06/2020", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/-minutes-of-the-53rd-bog-dated-30th-june-2020_426d53aa-2d3e-4be9-bd16-20777f5a1d57_0.pdf",
    sha256: "f38b53b6afc35d286ecf2d66b677aab9a080916bdfa853818ed597709becb011", bytes: 541791, pages: 10 },
  { file: "bog__Minutes_of_the_52nd_BoG_Meeting_Held_on_01_02_2020.pdf", label: "Minutes of the 52nd BoG Meeting Held on 01/02/2020", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-52nd-bog-dated-01st-february-2020_b64018fb-6424-46ea-b657-07f12c161a4e_0.pdf",
    sha256: "ff5bccd4fcdc3498213221f6c21f5ec3044810b34605263c50f6145bd3e50754", bytes: 648375, pages: 15 },
  { file: "bog__Minutes_of_the_51st_BoG_Meeting_Held_on_04_11_2019.pdf", label: "Minutes of the 51st BoG Meeting Held on 04/11/2019", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-51st-bog-dated-04th-november-2019_534ce2b0-7ede-4500-81e7-63bbdd9d2d3e_0.pdf",
    sha256: "91a927179413b64267105f36f43b9a4b7c54480fa0700b5415b7d1b5c3dd9a17", bytes: 367971, pages: 7 },
  { file: "bog__Minutes_of_the_50th_BoG_Meeting_Held_on_20_09_2019.pdf", label: "Minutes of the 50th BoG Meeting Held on 20/09/2019", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/-minutes-of-the-50th-bog-meeting-dated-20092019_3c7c2e4f-b264-4e8f-ae5f-3d036d8c4070_0.pdf",
    sha256: "38caab807d96c4931c577428117cf02d75491b6910ebeef1a6b82127762fb005", bytes: 336594, pages: 3 },
  { file: "bog__Minutes_of_the_49th_BoG_Meeting_Held_on_05_07_2019.pdf", label: "Minutes of the 49th BoG Meeting Held on 05/07/2019", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/-minutes-of-the-49th-bog-meeting-dated-05072019_32aedfdc-556f-4c35-a7e8-c8cf06b0c547_0.pdf",
    sha256: "6ec1e175487e26e0efb3d8625966fa085a345db58be207ecc9a48ecd11051f11", bytes: 341775, pages: 8 },
  { file: "bog__Minutes_of_the_48th_BoG_Meeting_Held_on_08_05_2019.pdf", label: "Minutes of the 48th BoG Meeting Held on 08/05/2019", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-48th-bog-meeting-dated-08052019_5e0e18fc-54d3-405b-986e-861f84eb92b2_0.pdf",
    sha256: "f516c5c5fbd1aebe444b32a79ccad1222fb61d1271ae4196dbedddc917b30cc4", bytes: 300126, pages: 7 },
  { file: "bog__Minutes_of_the_47th_BoG_Meeting_Held_on_05_02_2019.pdf", label: "Minutes of the 47th BoG Meeting Held on 05/02/2019", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-47th-bog-meeting-dated-05022019_9d79c7a2-e890-4cf4-b3e2-1cc23adde1bc_0.pdf",
    sha256: "da6235f16cb693cca0fd2612ae220a35248109a4634bae386a87e1fce037bb45", bytes: 230589, pages: 9 },
  { file: "bog__Minutes_of_the_46th_BoG_Meeting_Held_on_12_10_2018.pdf", label: "Minutes of the 46th BoG Meeting Held on 12/10/2018", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/-minutes-of-the-46th-bog-meeting-dated-12102018_8bb4b22c-3672-4571-a02f-50929c94c3a2_0.pdf",
    sha256: "f3d3612017d7e7ee97000352bdf26adc98949ec60302aebb27f8cd1fb0acdb0b", bytes: 179227, pages: 4 },
  { file: "bog__Minutes_of_the_45th_BoG_Meeting_Held_on_28_09_2018.pdf", label: "Minutes of the 45th BoG Meeting Held on 28/09/2018", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-45th-bog-meeting-dated-28092018_a51ed250-5ea9-4f64-90a6-087407568076_0.pdf",
    sha256: "43668d6eca5f66d3e8081a18b559598a49f33b2708d64fbf576848dfdacd1e45", bytes: 164899, pages: 2 },
  { file: "bog__Minutes_of_the_44th_BoG_Meeting_Held_on_05_09_2018.pdf", label: "Minutes of the 44th BoG Meeting Held on 05/09/2018", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-44th-bog-meeting-dated-05092018_1eeb0cb2-14ff-46ae-9915-7ffe0b77561b_0.pdf",
    sha256: "bf24edb5ae4880ca048b90636f002a3af71dd835809dbb9c250932003d376923", bytes: 188002, pages: 5 },
  { file: "bog__Minutes_of_the_43rd_BoG_Meeting_Held_on_20_06_2018.pdf", label: "Minutes of the 43rd BoG Meeting Held on 20/06/2018", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/-minutes-of-the-43rd-bogmeeting---dated-20062018_a7c393e2-9033-4a29-bbda-9512a8b0f8b6_0.pdf",
    sha256: "fe54c4aaa06ece2740add2303c1dd65a7c8dd7352b30e57f3077b9142faab6e7", bytes: 448240, pages: 7 },
  { file: "bog__Minutes_of_the_42nd_BoG_Meeting_Held_on_25_04_2018.pdf", label: "Minutes of the 42nd BoG Meeting Held on 25/04/2018", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/-minutes-of-the-42nd-bogmeeting---dated-25042018_d8bcf1be-a1d6-4cbb-97ee-5b1f0ce34caf_0.pdf",
    sha256: "c46e6cdf070a45c4998a30c2c5841d52c4568a08e5c9643fa928deee40e5691a", bytes: 109599, pages: 10 },
  { file: "bog__Minutes_of_the_41st_BoG_Meeting_Held_on_19_03_2018.pdf", label: "Minutes of the 41st BoG Meeting Held on 19/03/2018", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-41st-bogmeeting---dated-19032018_b31499b8-b710-4e1f-891a-e7bc00ae2149_0.pdf",
    sha256: "ed642ea0c5f098c42fc34b645e185a9a947ec52cbb694e7623dcb16412d7497d", bytes: 678105, pages: 8 },
  { file: "bog__Minutes_of_the_40th_BoG_Meeting_Held_on_22_12_2017.pdf", label: "Minutes of the 40th BoG Meeting Held on 22/12/2017", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-40th-bog-meeting---dated-22122017_d7917de5-57ba-41d0-8667-87823842666b_0.pdf",
    sha256: "74e0ed7790c3646db45dae0e8110a8fd470522ab23114665882cca75d5a7c5ad", bytes: 532517, pages: 10 },
  { file: "bog__Minutes_of_the_39th_BoG_Meeting_Held_on_30_10_2017.pdf", label: "Minutes of the 39th BoG Meeting Held on 30/10/2017", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-39th-bog-meeting---dated-30102017_b81e2c27-6d77-4525-a15c-eebe76667a54_0.pdf",
    sha256: "b29a84804bbee07148924e2d41179ec7aa7a15957aa7a050c98ddfb46d90d27d", bytes: 451355, pages: 7 },
  { file: "bog__Minutes_of_the_38th_BoG_Meeting_Held_on_23_09_2017.pdf", label: "Minutes of the 38th BoG Meeting Held on 23/09/2017", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/-minutes-of-the-38th-bog-meeting---dated-23092017_1c944ecd-c6b9-4edb-8064-e3247d19868e_0.pdf",
    sha256: "2ba32feab6035a5b27e59b08332829ed72c18f2fe7a49654eaabeb56bcd5b184", bytes: 59827, pages: 2 },
  { file: "bog__Minutes_of_the_37th_BoG_Meeting_Held_on_31_07_2017.pdf", label: "Minutes of the 37th BoG Meeting Held on 31/07/2017", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/-minutes-of-the-37th-bog-meeting---dated-31072017_58276ae2-be31-4dc0-843b-e9884cc9b44e_0.pdf",
    sha256: "062f95b39f840133b86084038e6fbee13ca44df6cb69b4dca97de38b9945cec8", bytes: 112647, pages: 6 },
  { file: "bog__Minutes_of_the_36th_BoG_Meeting_Held_on_22_04_2017.pdf", label: "Minutes of the 36th BoG Meeting Held on 22/04/2017", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-36th-bog-meeting---dated-22042017_dc110165-1146-4dd5-b76b-e8d13def1b75_0.pdf",
    sha256: "dad1267b48c8d6da505a20f4f444e45f2291f45ddb6df5283fe59651297fef74", bytes: 52161, pages: 3 },
  { file: "bog__Minutes_of_the_35th_BoG_Meeting_Held_on_30_03_2017.pdf", label: "Minutes of the 35th BoG Meeting Held on 30/03/2017", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/-minutes-of-the-35th-bog-meeting---dated-30032017_ad45ac29-cfa0-4434-9d72-10d48f45fa6d_0.pdf",
    sha256: "1484707072a8b50ab837ac78c91506af0606af27f82493c4de2344406ddf2481", bytes: 126608, pages: 3 },
  { file: "bog__Minutes_of_the_34th_BoG_Meeting_Held_on_13_02_2017.pdf", label: "Minutes of the 34th BoG Meeting Held on 13/02/2017", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-34th-bog-meeting---dated-13022017_2234474a-b611-434a-bae4-45103e4d2a57_0.pdf",
    sha256: "d68321d392dc461f90a6014094f11e694c49d723a4a54de80ab8dee484f09a82", bytes: 445519, pages: 4 },
  { file: "bog__Minutes_of_the_33rd_BoG_Meeting_Held_on_21_11_2016.pdf", label: "Minutes of the 33rd BoG Meeting Held on 21/11/2016", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-33rd-bog-meeting---dated-21112016_ddceecb4-fa00-4b0c-902a-d852ef910f7a_0.pdf",
    sha256: "de42d78e7ad8193510fc57a2bf05c656497c497708d75206d51ec48e4d373e81", bytes: 408402, pages: 6 },
  { file: "bog__Minutes_of_the_32nd_BoG_Meeting_Held_on_09_08_2016.pdf", label: "Minutes of the 32nd BoG Meeting Held on 09/08/2016", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/-minutes-of-the-32nd-bog-meeting---dated-09082016_85038fa9-4772-42a0-9e2c-6ca9c956730f_0.pdf",
    sha256: "4c73ff93f24d05ba1dca9d10aace272a3a0414fbb8038fc73fd353c8402b10b2", bytes: 320180, pages: 5 },
  { file: "bog__Minutes_of_the_31st_BoG_Meeting_Held_on_02_05_2016.pdf", label: "Minutes of the 31st BoG Meeting Held on 02/05/2016", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/-minutes-of-the-31st-bog-meeting---dated-02052016_c7edc1d6-190e-4ee5-ad26-532e134ff3d5_0.pdf",
    sha256: "fa40e12836d998f7e2b83766ab6d66ddceff9b7a63933795a58dd6b2d53d4ac8", bytes: 330644, pages: 4 },
  { file: "bog__Minutes_of_the_30th_BoG_Meeting_Held_on_05_02_2016.pdf", label: "Minutes of the 30th BoG Meeting Held on 05/02/2016", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/-minutes-of-the-30th-bogmeeting---dated-05022016_1b4a956e-0c46-4db2-ad36-083fa1d25db6_0.pdf",
    sha256: "d8adff66d837cae2523ca51992a47a43a7b9688e05f5c02b59bb9bcaa6c8b840", bytes: 323779, pages: 4 },
  { file: "bog__Minutes_of_the_29th_BoG_Meeting_Held_on_21_11_2015.pdf", label: "Minutes of the 29th BoG Meeting Held on 21/11/2015", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-29th-bogmeeting---dated-21112015_89ef9cd1-70bd-48e7-a501-cd461046ca8f_0.pdf",
    sha256: "928750c33aae87dc179a15f37a5d596d67d48398fe21cae08a0d18546da0f557", bytes: 418027, pages: 8 },
  { file: "bog__Minutes_of_the_28th_BoG_Meeting_Held_on_09_01_2015.pdf", label: "Minutes of the 28th BoG Meeting Held on 09/01/2015", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/-minutes-of-the-28th-bogmeeting---dated-09012015_c975dd70-4755-4341-9961-8008798bd968_0.pdf",
    sha256: "783c7e92ae0dc0e9c4e1e505a682f9c9864c0bc3d449f5108e5a2c8b98474fca", bytes: 132214, pages: 7 },
  { file: "bog__Minutes_of_the_27th_BoG_Meeting_Held_on_07_05_2014.pdf", label: "Minutes of the 27th BoG Meeting Held on 07/05/2014", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/-minutes-of-the-27th-bog-meeting---dated-07052014_ff9a2ae3-9c13-4259-980d-e4f76d29c284_0.pdf",
    sha256: "0e37721429a9d7a364f0d3c16da6b9a7b0aa07e55cc1dbca77350ea0642a3de5", bytes: 48002, pages: 8 },
  { file: "bog__Minutes_of_the_26th_BoG_Meeting_Held_on_28_03_2014.pdf", label: "Minutes of the 26th BoG Meeting Held on 28/03/2014", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-26th-bog-meeting---dated-28032014_2c4634bb-d419-4eff-87b8-eefdabf60190_0.pdf",
    sha256: "bf7102690b252d5acb03b7096132ea423daa5c181cb57a37debe9634e9e3f0f0", bytes: 148121, pages: 12 },
  { file: "bog__Minutes_of_the_25th_BoG_Meeting_Held_on_14_12_2013.pdf", label: "Minutes of the 25th BoG Meeting Held on 14/12/2013", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-25th-bog-meeting---dated-14122013_bbbd408b-4c12-4d9c-aee9-a521234a505c_0.pdf",
    sha256: "15a660e50416b7f77286103bce0b704e83da1eb1e7f00d75b2f6ba20ac927405", bytes: 23064, pages: 5 },
  { file: "bog__Minutes_of_the_24th_BoG_Meeting_Held_on_22_10_2013.pdf", label: "Minutes of the 24th BoG Meeting Held on 22/10/2013", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/-minutes-of-the-24th-bog-meeting---dated-22102013_c48adda8-ac36-4a36-953e-c88c7cfb517d_0.pdf",
    sha256: "97afe151379e673fc636c4bd2a707f45fee927d5188fffa5ed3b150a19f28660", bytes: 61865, pages: 10 },
  { file: "bog__Minutes_of_the_23rd_BoG_Meeting_Held_on_24_07_2013.pdf", label: "Minutes of the 23rd BoG Meeting Held on 24/07/2013", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-23rd-bog-meeting---dated-24072013_8cd03cd3-189b-447e-811c-6b933e28218c_0.pdf",
    sha256: "c76540e0b93399bb39ec20e8a10d2e996352b69c7f637b2f4ffe0b6715e6873b", bytes: 145612, pages: 11 },
  { file: "bog__Minutes_of_the_22nd_BoG_Meeting_Held_on_27_04_2013.pdf", label: "Minutes of the 22nd BoG Meeting Held on 27/04/2013", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/-minutes-of-the-22nd-bog-meeting---dated-27042013_1fe7b551-e0af-4b7a-a71c-3a1f08b3a265_0.pdf",
    sha256: "851023ffef03f5bbb9219ee57d1ce1e403f86640633502682ee246f2b850ef67", bytes: 141544, pages: 9 },
  { file: "bog__Minutes_of_the_21st_BoG_Meeting_Held_on_03_01_2013.pdf", label: "Minutes of the 21st BoG Meeting Held on 03/01/2013", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-21st-bog-meeting---dated-03012013_79128e10-c9af-4d8d-9b02-f04f5d97ee5b_0.pdf",
    sha256: "5cf9b43ab4600d48a1945443b5893e610980978e9ca950d81447df21f3f62d29", bytes: 66029, pages: 9 },
  { file: "bog__Minutes_of_the_20th_BoG_Meeting_Held_on_16_10_2012.pdf", label: "Minutes of the 20th BoG Meeting Held on 16/10/2012", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-20th-bog-meeting---dated-16102012_ea1ce6af-3fa2-4861-a96e-b23cc1ce891f_0.pdf",
    sha256: "a97d8cfcfff1258048ec65d80990af8a868819a59f08d4ff4c61734425d2ada6", bytes: 100252, pages: 9 },
  { file: "bog__Minutes_of_the_19th_BoG_Meeting_Held_on_16_05_2012.pdf", label: "Minutes of the 19th BoG Meeting Held on 16/05/2012", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-19th-bog-meeting---dated-16052012_29b84347-4678-4e6b-9681-bdfb08c5f9ad_0.pdf",
    sha256: "fd2ee16e7c4edded24b7f780888c9bc172fba1a97628c9cec03d2931531a681b", bytes: 78492, pages: 3 },
  { file: "bog__Minutes_of_the_18th_BoG_Meeting_Held_on_03_05_2012.pdf", label: "Minutes of the 18th BoG Meeting Held on 03/05/2012", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-18th-bog-meeting---dated-03052012_23b312a1-3e09-4259-8d4e-bb0e0aeb274d_0.pdf",
    sha256: "8a2bb70a7c46944ac10c1e927fe07cdd316e3b4fc0f80583d3a1e9a656051523", bytes: 72505, pages: 3 },
  { file: "bog__Minutes_of_the_17th_BoG_Meeting_Held_on_18_01_2012.pdf", label: "Minutes of the 17th BoG Meeting Held on 18/01/2012", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-17th-bogmeeting---dated-18012012_bbe9e97c-3278-45ec-9777-8d67d82c192b_0.pdf",
    sha256: "25d6a0abbd71fbecdff2ff884eff030fb105bccac91eb90b31cba9fed728bab4", bytes: 94617, pages: 8 },
  { file: "bog__Minutes_of_the_16th_BoG_Meeting_Held_on_31_08_2011.pdf", label: "Minutes of the 16th BoG Meeting Held on 31/08/2011", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-16th-bogmeeting---dated-31082011_16aae5a3-e6c2-4ffb-a3b0-ea1978218038_0.pdf",
    sha256: "6681a2eaa0f590d65af16ac457ec4dd2b33eb4949eb18beaba373d79ea62cb4b", bytes: 1716845, pages: 4 },
  { file: "bog__Minutes_of_the_14th_BoG_Meeting_Held_on_15_10_2010.pdf", label: "Minutes of the 14th BoG Meeting Held on 15/10/2010", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-14th-bog-meeting-held-on-15102010_302_0.pdf",
    sha256: "196eb1a077a062b639d3d0d06d0814c6f82ca1df67a4a341f4dead062e5903d5", bytes: 536831, pages: 10 },
  { file: "bog__Minutes_of_the_13th_BoG_Meeting_Held_on_30_05_2010.pdf", label: "Minutes of the 13th BoG Meeting Held on 30/05/2010", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-13th-bog-meeting-held-on-30052010_303_0.pdf",
    sha256: "2b4f2a24df9eb9bbbf37dadc5cb1bd83d43b7313255622c770d2b86297325d14", bytes: 358011, pages: 6 },
  { file: "bog__Minutes_of_the_12th_BoG_Meeting_Held_on_31_03_2010.pdf", label: "Minutes of the 12th BoG Meeting Held on 31/03/2010", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-12th-bog-meeting-held-on-31032010_21015dbb-d4f5-4aaa-9db2-cc8b2ed062c6_0.pdf",
    sha256: "16802dc9572ffc2ef048d4ca258b16d21d1939bc6a890c74452716032cc78088", bytes: 311483, pages: 6 },
  { file: "bog__Minutes_of_the_11th_BoG_Meeting_Held_on_15_12_2009.pdf", label: "Minutes of the 11th BoG Meeting Held on 15/12/2009", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-11th-bog-meeting-held-on-15122009_28d08753-9f7c-4b74-966a-2b79c320c389_0.pdf",
    sha256: "da6611ea28c9a2a489944460ddd88751df7411cbb5d7b430e0b73a9c14502d2e", bytes: 638707, pages: 13 },
  { file: "bog__Minutes_of_the_10th_BoG_Meeting_Held_on_14_10_2009.pdf", label: "Minutes of the 10th BoG Meeting Held on 14/10/2009", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-10th-bog-meeting-held-on-14102009_ecd2088d-add4-4279-813b-702ea8fee205_0.pdf",
    sha256: "ff0b0ad4c32da2bb2857a90dd46937d3f85ae4793d7357af4b2696161b5dd0bc", bytes: 314410, pages: 5 },
  { file: "bog__Minutes_of_the_09th_BoG_Meeting_Held_on_26_08_2009.pdf", label: "Minutes of the 09th BoG Meeting Held on 26/08/2009", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-09th-bog-meeting-held-on-26082009_307_0.pdf",
    sha256: "5860ebdad4cc4d6b48ade2b5ada158191017009f2f50c6cd29508245f2c75187", bytes: 326447, pages: 7 },
  { file: "bog__Minutes_of_the_08th_BoG_Meeting_Held_on_04_06_2009.pdf", label: "Minutes of the 08th BoG Meeting Held on 04/06/2009", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-08th-bog-meeting-held-on-04062009_308_0.pdf",
    sha256: "f9cc72c68afc5ce82399743c09358736f3a36cc5cdbb3b73d75b36097726b0ba", bytes: 485410, pages: 8 },
  { file: "bog__Minutes_of_the_07th_BoG_Meeting_Held_on_29_03_2009.pdf", label: "Minutes of the 07th BoG Meeting Held on 29/03/2009", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-07th-bog-meeting-held-on-29032009_9d353968-3fed-4a59-9b44-54e11d9e4cbd_0.pdf",
    sha256: "f3acb4ce2cae0bba81771a8abc760ccee1baff214c8cb6908f29fb45bf1e32ff", bytes: 410915, pages: 7 },
  { file: "bog__Minutes_of_the_06th_BoG_Meeting_Held_on_26_02_2009.pdf", label: "Minutes of the 06th BoG Meeting Held on 26/02/2009", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-06th-bog-meeting-held-on-26022009_2e984b8c-42f3-4542-a188-19cefcfcf4f4_0.pdf",
    sha256: "8ff496c7b3bb1dfcaa5a0945fd036aa222dc3e12b28bcbc96fe665cbe370659a", bytes: 472791, pages: 7 },
  { file: "bog__Minutes_of_the_05th_BoG_Meeting_Held_on_04_06_2009.pdf", label: "Minutes of the 05th BoG Meeting Held on 04/06/2009", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-05th-bog-meeting-held-on-04062009_af8178a7-2b5c-4dc9-8fd5-df8abb844ea9_0.pdf",
    sha256: "f82f397b4eb29f53abdddeb5a737dad93195dd7502c56ee484eb3199d5d56058", bytes: 474004, pages: 8 },
  { file: "bog__Minutes_of_the_04th_BoG_Meeting_Held_on_17_08_2008.pdf", label: "Minutes of the 04th BoG Meeting Held on 17/08/2008", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-04th-bog-meeting-held-on-17082008_35b75dc4-5ae3-4431-be1d-c020c88b5613_0.pdf",
    sha256: "b035dd38927c4315f4128714172d894ee7d498238ac3501513be12befa842d2a", bytes: 386025, pages: 7 },
  { file: "bog__Minutes_of_the_03rd_BoG_Meeting_Held_on_18_03_2008.pdf", label: "Minutes of the 03rd BoG Meeting Held on 18/03/2008", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-03rd-bog-meeting-held-on-18032008_3ed6ca4e-63f8-4334-816b-b0b153449ee1_0.pdf",
    sha256: "9ad45a8605325c882a1d528bcfdbd0ac1f93ad99bd3ba2130cf8a82d101c841d", bytes: 395461, pages: 6 },
  { file: "bog__Minutes_of_the_02nd_BoG_Meeting_Held_on_17_01_2008.pdf", label: "Minutes of the 02nd BoG Meeting Held on 17/01/2008", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-02nd-bog-meeting-held-on-17012008_fd937e6e-6ef4-4f65-b80f-db57b8f717e4_0.pdf",
    sha256: "3c8dbbd14fa68b143ca89e9fc581a5de78208527ffbf7ee25161215e1074b9bd", bytes: 314593, pages: 5 },
  { file: "bog__Minutes_of_the_01st_BoG_Meeting_Held_on_07_10_2002.pdf", label: "Minutes of the 01st BoG Meeting Held on 07/10/2002", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-01st-bog-meeting-held-on-07102002_373637aa-7324-4b13-9935-9306c1084965_0.pdf",
    sha256: "284537a380b2a820450b54eab2f41ccfbbcabba954ba7fb17e201de849f9b4c1", bytes: 1220849, pages: 35 },
  { file: "senate__Minutes_of_the_106th_Senate_Meeting_Held_on_22_July_2026.pdf", label: "Minutes of the 106th Senate Meeting Held on 22 July 2026", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-106th-senate-meeting-held-on-22-july-2026_f117bb86-cbfe-4f73-a5e8-4e4a473fb988_0.pdf",
    sha256: "901489768c93a227f41b6293a8864bbf82e9b2415c3d5b3960f4220237567c3f", bytes: 605969, pages: 24 },
  { file: "senate__Minutes_of_the_105th_Senate_Meeting_Held_on_16_March_2026.pdf", label: "Minutes of the 105th Senate Meeting Held on 16 March 2026", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-105th-senate-meeting-held-on-16-march-2026_df7c073a-b172-44a9-8f47-dcaf6c4fc60f_0.pdf",
    sha256: "5f8af33ff03a66092d3618172fef8620bbbad8cf07936bc99ca4aa7e7dbf9c5b", bytes: 401493, pages: 13 },
  { file: "senate__Minutes_of_the_104th_Senate_Meeting_Held_on_03_12_2025.pdf", label: "Minutes of the 104th Senate Meeting Held on 03-12-2025", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-104th-senate-meeting-held-on-03-12-2025_259ddf5a-c2f8-4958-8e0d-fde6ed62e844_0.pdf",
    sha256: "1eba236ac48f3eab900e2c6f48fad2202e1586e83fb02092e73b235e7dfed5cc", bytes: 641340, pages: 15 },
  { file: "senate__Minutes_of_the_103rd_Senate_Meeting_Held_on_17_11_2025.pdf", label: "Minutes of the 103rd Senate Meeting Held on 17-11-2025", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the--103rd---senate-meeting-held-on-17-11-2025_9c88420e-2041-4dae-9894-458fb612797f_0.pdf",
    sha256: "edb65e97606494b32a40b0fe53ed2abb6e85344a715d2681f0eb625210da5e94", bytes: 269583, pages: 4 },
  { file: "senate__Minutes_of_the_102nd_Senate_Meeting_Held_on_27_08_2025.pdf", label: "Minutes of the 102nd Senate Meeting Held on 27-08-2025", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the--102nd---senate-meeting-held-on-27-08-2025_d93aa3b5-c88b-4419-9503-27f76df5af11_0.pdf",
    sha256: "d58311e74a33d47878830918494733eab7b629dd55676dd8abefca8448d4c4bf", bytes: 293320, pages: 4 },
  { file: "senate__Minutes_of_the_101st_Senate_Meeting_Held_on_28_07_2025.pdf", label: "Minutes of the 101st Senate Meeting Held on 28-07-2025", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the--101st---senate-meeting-held-on-28-07-2025_1b659c1f-116c-4a45-bae9-a58b8df25cbe_0.pdf",
    sha256: "9930b30f2d257863a3129f71226d81cd8dd4b8d12883c882d50002206f3713b2", bytes: 722791, pages: 22 },
  { file: "senate__Minutes_of_the_100th_Senate_Meeting_Held_on_23_04_2025.pdf", label: "Minutes of the 100th Senate Meeting Held on 23-04-2025", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-100th-senate-meeting-held-on-23-04-2025_e53e7883-72b4-4550-a5c8-a20fa7946659_0.pdf",
    sha256: "c32512a3e4bd6241cdd1dd88d7af9740bec338e7e8f7779769201cd0327fa669", bytes: 561922, pages: 19 },
  { file: "senate__Minutes_of_the_99th_Senate_Meeting_Held_on_05_12_2024.pdf", label: "Minutes of the 99th Senate Meeting Held on 05-12-2024", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-99th-senate-meeting-held-on-05th-december-2024_205ee4cd-93d7-47e6-9c6f-5df5002d2d08_0.pdf",
    sha256: "687acd3273d42f45b3daba18136e563172de84f2b134e65ca5a22935df86da00", bytes: 499506, pages: 37 },
  { file: "senate__Minutes_of_the_98th_Senate_Meeting_Held_on_02_09_2024.pdf", label: "Minutes of the 98th Senate Meeting Held on 02-09-2024", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-98th-senate-meeting-held-on-02-09-2024_f23f87f4-2d90-4f9e-8f59-08af7fea4af7_0.pdf",
    sha256: "ba0557e70713e4a0cbc67dc95c5673042860eb47be23baff089d3161d5df27d6", bytes: 2329182, pages: 41 },
  { file: "senate__Minutes_of_the_97th_Senate_Meeting_Held_on_05_08_2024.pdf", label: "Minutes of the 97th Senate Meeting Held on 05-08-2024", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-97th-senate-meeting-held-on-05-08-2024_92f18f37-0d08-41db-be46-a8d51111b610_0.pdf",
    sha256: "c32ba5e2fb6f96d3f3d21b2d6aca8b7cdc48b5c1a711bc46a2e406f8432d2ca9", bytes: 155500, pages: 9 },
  { file: "senate__Minutes_of_the_96th_Senate_Meeting_Held_on_08_05_2024.pdf", label: "Minutes of the 96th Senate Meeting Held on 08-05-2024", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-96th-senate-meeting-held-on-08-05-2024_fc5a6baa-7642-48ae-8426-cb66d9c29c2b_0.pdf",
    sha256: "2d901226b5dad13abced9e7c14dfbb03074692bc95cb7640e2fb5f1603fbbe3b", bytes: 291515, pages: 28 },
  { file: "senate__Minutes_of_the_95th_Senate_Meeting_Held_on_11_01_2024.pdf", label: "Minutes of the 95th Senate Meeting Held on 11-01-2024", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-95th-senate-meeting-held-on-11-01-2024_17f8c5cc-c4ec-4173-a83e-80290ae328da_0.pdf",
    sha256: "0f2d7b4193f12e4510867b1ce51e8cca6a7bfcb594b3b434e2b88dfa7e7ecf71", bytes: 215876, pages: 15 },
  { file: "senate__Minutes_of_the_94th_Senate_Meeting_Held_on_22_08_2023.pdf", label: "Minutes of the 94th Senate Meeting Held on 22-08-2023", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-94th-senate-meeting-held-on-22-08-2023_b2d81314-4b6e-48bc-886d-f4a64cf126dd_0.pdf",
    sha256: "f02bfc2f924e8c2fe1537d86d40d1a45545aedb960d663d240336e194860f593", bytes: 114696, pages: 7 },
  { file: "senate__Minutes_of_the_93rd_Senate_Meeting_Held_on_17_07_2023.pdf", label: "Minutes of the 93rd Senate Meeting Held on 17-07-2023", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-93rd-senate-meeting-held-on-17-07-2023_f661d9f7-48dd-4881-a78e-45a1d194d070_0.pdf",
    sha256: "55f33348164b75b8ce7a10e689c2aec7a2e732aeac3e19b58ebadc2facc951c8", bytes: 1120420, pages: 10 },
  { file: "senate__Minutes_of_the_92nd_Senate_Meeting_Held_on_15_05_2023.pdf", label: "Minutes of the 92nd Senate Meeting Held on 15-05-2023", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-92nd-senate-meeting-held-on-15-05-2023_fd9b956d-ffbc-462d-93ef-982fbc4dee78_0.pdf",
    sha256: "b54d9e9a62977f38d745b06bb94c7510caa9dec977164465bf94af609e118eba", bytes: 295756, pages: 11 },
  { file: "senate__Minutes_of_the_91st_Senate_Meeting_Held_on_29_03_2023.pdf", label: "Minutes of the 91st Senate Meeting Held on 29-03-2023", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-91st-senate-meeting-held-on-29-03-2023_25b70a1d-6e6c-4927-bd6c-227a0179ba16_0.pdf",
    sha256: "bd92ac4962e2d808432dfecb88b2276942e5137d1e73e4270da1a34fc7e68ce7", bytes: 158263, pages: 8 },
  { file: "senate__Minutes_of_the_90th_Senate_Meeting_Held_on_23_01_2023.pdf", label: "Minutes of the 90th Senate Meeting Held on 23-01-2023", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-90th-senate-meeting-held-on-23-01-2023_74a15d3b-4dfb-4622-b71e-52323af8a7fa_0.pdf",
    sha256: "249024de20a3a14c175abb67d734db09641bc0e439f919b4c49c8fbfd01ffb22", bytes: 4908262, pages: 59 },
  { file: "senate__Minutes_of_the_89th_Senate_Meeting_Held_on_01_11_2022.pdf", label: "Minutes of the 89th Senate Meeting Held on 01-11-2022", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-89th-senate-held-on-01-11-2022_8a150d90-eef9-4645-b89f-332430b2106b_0.pdf",
    sha256: "d7b3209025c30a565801baa5eb45ef2842e6b503cdb32b221a18650aa1fe23ed", bytes: 139780, pages: 11 },
  { file: "senate__Minutes_of_the_88th_Senate_Meeting_Held_on_30_08_2022.pdf", label: "Minutes of the 88th Senate Meeting Held on 30-08-2022", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-88th-senate-held-on-30-08-2022_95e0af47-6741-4cb6-8d4f-f4b5556f07aa_0.pdf",
    sha256: "79016901705d9bcae8df152373f9d1722d747b38b7d7c5386124b77f9b759c58", bytes: 118143, pages: 6 },
  { file: "senate__Minutes_of_the_87th_Senate_Meeting_Held_on_14_07_2022.pdf", label: "Minutes of the 87th Senate Meeting Held on 14-07-2022", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-87th-senate-held-on-14-07-2022_45885fa8-b93e-4902-99e7-ae260f28b8c6_0.pdf",
    sha256: "515643d657439462327a8f861f1723cc05beb235e8f1967c9be063b12d846922", bytes: 418730, pages: 14 },
  { file: "senate__Minutes_of_the_86th_Senate_Meeting_Held_on_05_01_2022.pdf", label: "Minutes of the 86th Senate Meeting Held on 05-01-2022", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-86th-senate-held-on-05-01-2022_5e1da8db-0706-4251-a39d-301bb72bf81f_0.pdf",
    sha256: "294ffa8f5442fc578b731a3e0032b86c0f967857df2da4a9de73b49a4c8a5c1a", bytes: 204068, pages: 14 },
  { file: "senate__Minutes_of_the_85th_Senate_Meeting_Held_on_21_10_2021.pdf", label: "Minutes of the 85th Senate Meeting Held on 21-10-2021", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-85th-senate--held-on-21-10-2021_eccb0cdf-0a21-4dac-bbe0-b49124416346_0.pdf",
    sha256: "d3aea8ce8f4fb5a6bf0fe91b429d01865e5f4550497949d021f278e01492e6f7", bytes: 285693, pages: 4 },
  { file: "senate__Minutes_of_the_84th_Senate_Meeting_Held_on_15_06_2021.pdf", label: "Minutes of the 84th Senate Meeting Held on 15-06-2021", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-84th-senate-held-on-15-06-2021_14bca2ba-ac1e-412a-b88a-4b1fce57fc0e_0.pdf",
    sha256: "5c85591fb3630bf41c25c3f2e91900331440d2d5cd581e9ec43c67327e7ae10e", bytes: 922113, pages: 8 },
  { file: "senate__Minutes_of_the_83rd_Senate_Meeting_Held_on_17_05_2021.pdf", label: "Minutes of the 83rd Senate Meeting Held on 17 - 05 - 2021", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-83rd-senate--held-on-17---05---2021_f53aa6cb-dda9-43cf-aad7-3e969fe9367f_0.pdf",
    sha256: "c9aa43a41682c5bfa1f9254d4cb26df85dc45cbecee8ea9b96d11321a5bcfcbf", bytes: 206969, pages: 5 },
  { file: "senate__Minutes_of_the_82nd_Senate_Meeting_Held_on_17_03_2021.pdf", label: "Minutes of the 82nd Senate Meeting Held on 17 - 03 - 2021", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-82nd-senate--held-on-17---03---2021_63db71f3-87d2-4455-a8da-f5461a629368_0.pdf",
    sha256: "454064222062743e61e1af43f9664509b256925e9e1ee024329bb9df3ca67c6e", bytes: 223267, pages: 7 },
  { file: "senate__Minutes_of_the_81st_Senate_Meeting_Held_on_23_11_2020.pdf", label: "Minutes of the 81st Senate Meeting Held on 23 - 11- 2020", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-81st-senate--held-on-23---11--2020_707a4a38-bf6f-4587-83d2-b2a0ef8178c0_0.pdf",
    sha256: "fb1987d95fa7c1c21247806216fbb7b4b0dccfd44fab2dc45e8fce271daaef08", bytes: 427549, pages: 4 },
  { file: "senate__Minutes_of_the_80th_Senate_Meeting_Held_on_23_10_2020.pdf", label: "Minutes of the 80th Senate Meeting Held on 23 - 10 - 2020", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-80th-senate--held-on-23---10---2020_ba2f6bf3-b269-4506-b3f7-8541cd6a90f8_0.pdf",
    sha256: "72cc354be4486d0a08c30b6d04752d80d9a23b49f92af4bdf714e2c21de8f6b6", bytes: 352704, pages: 3 },
  { file: "senate__Minutes_of_the_79th_Senate_Meeting_Held_on_28_09_2020.pdf", label: "Minutes of the 79th Senate Meeting Held on 28 - 09 - 2020", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-79th-senate--held-on-28---09---2020_ccdc0a37-7a18-44dc-81c2-14eb7ae8c55f_0.pdf",
    sha256: "cb9acc5a7758a821ff75eda784ff792760abcfbf73158efe15d34537849329a2", bytes: 397416, pages: 4 },
  { file: "senate__Minutes_of_the_78th_Senate_Meeting_Held_on_24_06_2020.pdf", label: "Minutes of the 78th Senate Meeting Held on 24 - 06 - 2020", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-78th-senate--held-on-24---06---2020_aac5763a-c7e8-4f65-8308-006eec0a5823_0.pdf",
    sha256: "486e4265f48fcd8d84bd2238a362be362c348fbe7d9029636e0339e6c61ce32a", bytes: 392982, pages: 7 },
  { file: "senate__Minutes_of_the_77th_Senate_Meeting_Held_on_20_03_2020.pdf", label: "Minutes of the 77th Senate Meeting Held on 20 - 03 - 2020", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-77th-senate--held-on-20---03---2020_b69fb8a7-ed27-4de6-9719-e082a20ff1ed_0.pdf",
    sha256: "25d8bd4e86585e779c4917356f2a00a68b93a7964be9674063abc27ff9881cbd", bytes: 344364, pages: 2 },
  { file: "senate__Minutes_of_the_76th_Senate_Meeting_Held_on_13_03_2020.pdf", label: "Minutes of the 76th Senate Meeting Held on 13 - 03 - 2020", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-76th-senate--held-on-13---03---2020_d37c7548-266c-407b-8aaf-964b8de25c40_0.pdf",
    sha256: "6a79f3f934c0bd3c9763b0f11fee2a577efa912df7f7f74fd72aca1f2aef9900", bytes: 401588, pages: 4 },
  { file: "senate__Minutes_of_the_75th_Senate_Meeting_Held_on_11_02_2020.pdf", label: "Minutes of the 75th Senate Meeting Held on 11 - 02 - 2020", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-75th-senate--held-on-11---02---2020_4bbb1074-433e-4cf2-b208-a55a95d7b55f_0.pdf",
    sha256: "889d0d7d92c57e10c6b0c6990cfad9c31fe4bb4ceda8a806bb3802559159526f", bytes: 543144, pages: 8 },
  { file: "senate__Minutes_of_the_74th_Senate_Meeting_Held_on_29_11_2019.pdf", label: "Minutes of the 74th Senate Meeting Held on 29 - 11 - 2019", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-74th-senate--held-on-29---11---2019_b67a19e3-fc42-4052-ab2a-6fd8e5682c0e_0.pdf",
    sha256: "2a8fc07bab8da9d0c99c85ad4e074e97df0c00a5d26b6e16463d05e9b94f55d5", bytes: 569079, pages: 7 },
  { file: "senate__Minutes_of_the_73rd_Senate_Meeting_Held_on_24_10_2019.pdf", label: "Minutes of the 73rd Senate Meeting Held on 24 - 10 - 2019", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-73rd-senate--held-on-24---10---2019_2045b23c-5107-4a34-8593-57750a6e1504_0.pdf",
    sha256: "7c509c724e0067ce145de49f828b119b5ac2aee0bfaecae6712f15a434cf9fbf", bytes: 158470, pages: 3 },
  { file: "senate__Minutes_of_the_72nd_Senate_Meeting_Held_on_17_09_2019.pdf", label: "Minutes of the 72nd Senate Meeting Held on 17 - 09 - 2019", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-72nd-senate--held-on-17---09---2019_df940921-b5ab-4bed-aeed-6d874e0940ba_0.pdf",
    sha256: "dd1d710835f301b01bd85e9c8a2b817ac86e4f1221300b36bc1d58fcfad03bcb", bytes: 277724, pages: 3 },
  { file: "senate__Minutes_of_the_71st_Senate_Meeting_Held_on_16_07_2019.pdf", label: "Minutes of the 71st Senate Meeting Held on 16 - 07 - 2019", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-71st-senate--held-on-16---07---2019_85fde7b2-6447-4bcf-8879-9ad977397815_0.pdf",
    sha256: "47c14d91f70cb05454897720c497a0749482d906a792e3f80f72535946da281a", bytes: 465345, pages: 7 },
  { file: "senate__Minutes_of_the_70th_Senate_Meeting_Held_on_02_04_2019.pdf", label: "Minutes of the 70th Senate Meeting Held on 02 - 04 - 2019", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-70th-senate--held-on-02---04---2019_7a23873b-25eb-443a-832b-04b677a01d55_0.pdf",
    sha256: "80294aa5eccb346d03ae67e135d41c55681d52718b6eaed31fdf06d5651872f1", bytes: 425762, pages: 7 },
  { file: "senate__Minutes_of_the_69th_Senate_Meeting_Held_on_04_01_2019.pdf", label: "Minutes of the 69th Senate Meeting Held on 04 - 01 - 2019", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-69th-senate--held-on-04---01---2019_f0201769-1b3d-462a-be6f-fed9244ca01c_0.pdf",
    sha256: "b362d52a1e6116d6df83a70afe8586512a37e9091e40d261b873d5343cf364a5", bytes: 154662, pages: 4 },
  { file: "senate__Minutes_of_the_68th_Senate_Meeting_Held_on_09_11_2018.pdf", label: "Minutes of the 68th Senate Meeting Held on 09 - 11 - 2018", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-68th-senate--held-on-09---11---2018_08491542-8f3b-4a27-9b58-9bc17d2189f3_0.pdf",
    sha256: "0fd8655fef0f1720deee083db470a56538ee4ad403872e0589cd323d41b434c5", bytes: 428491, pages: 6 },
  { file: "senate__Minutes_of_the_67th_Senate_Meeting_Held_on_19_09_2018.pdf", label: "Minutes of the 67th Senate Meeting Held on 19 - 09 - 2018", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-67th-senate--held-on-19---09---2018_1e49db2b-b25f-4137-b89c-0e29934ed1ec_0.pdf",
    sha256: "006d157b17205cf3217e9347452e39e7c37054f1540351ecb363e20e944a8d17", bytes: 346529, pages: 3 },
  { file: "senate__Minutes_of_the_66th_Senate_Meeting_Held_on_23_07_2018.pdf", label: "Minutes of the 66th Senate Meeting Held on 23 - 07 - 2018", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-66th-senate--held-on-23---07---2018_44948cac-36ca-4a06-89fb-bfbf228fbc22_0.pdf",
    sha256: "4112a91859f721ccbccc71ea69cb62a809f7237e72f1e5106d6f01d1e3553ccd", bytes: 419630, pages: 4 },
  { file: "senate__Minutes_of_the_65th_Senate_Meeting_Held_on_09_07_2018.pdf", label: "Minutes of the 65th Senate Meeting Held on 09 - 07 - 2018", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-65th-senate--held-on-09---07---2018_7f1d06b9-a041-4dc4-bbc4-8e40f3efce82_0.pdf",
    sha256: "233c4a36592cd1f1ad04f1c78cdddd3a86ab93a77b4afa6fd16b549da37503a6", bytes: 407394, pages: 4 },
  { file: "senate__Minutes_of_the_64th_Senate_Meeting_Held_on_09_05_2018.pdf", label: "Minutes of the 64th Senate Meeting Held on 09 - 05 - 2018", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-64th-senate--held-on-09---05---2018_34cd8b7b-6d26-4ad4-a731-1ca5691e890f_0.pdf",
    sha256: "4cffdb0364ec70d368c09747f5ce2c9337295fd564d35eb6180b2d9ab799c581", bytes: 139249, pages: 6 },
  { file: "senate__Minutes_of_the_63rd_Senate_Meeting_Held_on_14_02_2018.pdf", label: "Minutes of the 63rd Senate Meeting Held on 14 - 02 - 2018", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-63rd-senate--held-on-14---02---2018_f879ca01-c49f-43da-9169-d919ee5f6cb9_0.pdf",
    sha256: "e06c901c45e65507346a0f3b82eb6f4fee7fc7c615d9f479bd223dc71cd51ec5", bytes: 162480, pages: 6 },
  { file: "senate__Minutes_of_the_62nd_Senate_Meeting_Held_on_28_11_2017.pdf", label: "Minutes of the 62nd Senate Meeting Held on 28 - 11 - 2017", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-62nd-senate--held-on-28---11---2017_aca2ca2d-ca72-47fe-a8d0-03ab480b52d1_0.pdf",
    sha256: "77572dbfd726613d02a1300e42eea16f2e10e8481c728d3c8b60abb2caafb3f0", bytes: 379832, pages: 4 },
  { file: "senate__Minutes_of_the_61st_Senate_Meeting_Held_on_14_09_2017.pdf", label: "Minutes of the 61st Senate Meeting Held on 14 - 09 - 2017", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-61st-senate--held-on-14---09---2017_90824d03-a3d8-4405-8fdd-4a15667de472_0.pdf",
    sha256: "cb19537b797c771bdbea17f2f5677416997198226655263d15ea764838b78e4b", bytes: 239153, pages: 5 },
  { file: "senate__Minutes_of_the_60th_Senate_Meeting_Held_on_12_07_2017.pdf", label: "Minutes of the 60th Senate Meeting Held on 12 - 07 - 2017", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-60th-senate--held-on-12---07---2017_f12c7e63-2464-4431-8a98-74a5397a0c36_0.pdf",
    sha256: "0164bc120ad3c722c53bc47ee4d6d06089ee2144e99022614742c4342b1cc26a", bytes: 288304, pages: 7 },
  { file: "senate__Minutes_of_the_59th_Senate_Meeting_Held_on_12_05_2017.pdf", label: "Minutes of the 59th Senate Meeting Held on 12 - 05 - 2017", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-59th-senate--held-on-12---05---2017_a20559bf-bb19-4e08-a5bc-64e9fae9c434_0.pdf",
    sha256: "ce050a8d2f1768940219d5524c2c21e0e54e4aa8f7578a0bd6038510d93f7384", bytes: 280296, pages: 5 },
  { file: "senate__Minutes_of_the_58th_Senate_Meeting_Held_on_22_12_2016.pdf", label: "Minutes of the 58th Senate Meeting Held on 22 - 12 - 2016", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-58th-senate--held-on-22---12---2016_fee81ded-e0e9-4c79-800d-95637192f3fd_0.pdf",
    sha256: "98ed4bdceeaba89fa2deb49677d14490abb25068fad15d83a3450626cd5ebe21", bytes: 145489, pages: 4 },
  { file: "senate__Minutes_of_the_57th_Senate_Meeting_Held_on_04_10_2016.pdf", label: "Minutes of the 57th Senate Meeting Held on 04 - 10 - 2016", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-57th-senate--held-on-04---10---2016_f7cbf51c-2455-4f4d-80dc-d2a2d4c101a3_0.pdf",
    sha256: "92fb8d9e50a685ef7850c634f027c2f57bfa2f04c3acb800ce7be92635f61fb7", bytes: 352209, pages: 5 },
  { file: "senate__Minutes_of_the_56th_Senate_Meeting_Held_on_29_07_2016.pdf", label: "Minutes of the 56th Senate Meeting Held on 29 - 07 - 2016", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-56th-senate--held-on-29---07---2016_d5b6f9db-138c-45d2-b33f-e2dd4deb998b_0.pdf",
    sha256: "6391d40f70e90a4d03fafcb727e99ff9f09737c8aae6d0055aee9dc9ca990015", bytes: 367768, pages: 6 },
  { file: "senate__Minutes_of_the_55th_Senate_Meeting_Held_on_30_03_2016.pdf", label: "Minutes of the 55th Senate Meeting Held on 30 - 03 - 2016", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-55th-senate--held-on-30---03---2016_16624ffd-ef68-4ba1-9d2a-46f95e57444a_0.pdf",
    sha256: "f644b810a4715c59a166210799f0af33ff51e20c321b41932b49e92bfa58bfbb", bytes: 379585, pages: 9 },
  { file: "senate__Minutes_of_the_54th_Senate_Meeting_Held_on_18_11_2015.pdf", label: "Minutes of the 54th Senate Meeting Held on 18 - 11 - 2015", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-54th-senate--held-on-18---11---2015_adfeb2b8-86b4-4581-af8b-e63e03e1760c_0.pdf",
    sha256: "5a5a8d7e7ea8dd45ad06119384ee4f7bcdf2a06bca3396f164c4e2d3f437def1", bytes: 354531, pages: 5 },
  { file: "senate__Minutes_of_the_53rd_Senate_Meeting_Held_on_03_11_2015.pdf", label: "Minutes of the 53rd Senate Meeting Held on 03 - 11 - 2015", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-53rd-senate--held-on-03---11---2015_90_0.pdf",
    sha256: "4d6a8b4d133dcdbe897a1d93c7b0d8e0166d065ea1a73ecae4b65c696980d588", bytes: 127138, pages: 3 },
  { file: "senate__Minutes_of_the_52nd_Senate_Meeting_Held_on_16_10_2015.pdf", label: "Minutes of the 52nd Senate Meeting Held on 16 - 10 - 2015", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-52nd-senate--held-on-16---10---2015_ab239e71-c595-4c6a-b438-0a4f661b59ed_0.pdf",
    sha256: "8f7d2d952deb336304135d719bde9df4c72315ac0eea3ed3990ed41649cddb19", bytes: 327017, pages: 3 },
  { file: "senate__Minutes_of_the_51st_Senate_Meeting_Held_on_07_10_2015.pdf", label: "Minutes of the 51st Senate Meeting Held on 07-10-2015", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-51st-senate--held-on-07-10-2015_03dce2d8-ec57-48b9-98cf-d11b253bf59d_0.pdf",
    sha256: "f062300df50949e31f79964fb5a0d7b4cbfbf626b0ffc3bc0587d49e1f3cfbe5", bytes: 363782, pages: 8 },
  { file: "senate__Minutes_of_the_50th_Senate_Meeting_Held_on_11_03_2015.pdf", label: "Minutes of the 50th Senate Meeting Held on 11-03-2015", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-50th-senate--held-on-11-03-2015_80a9d147-710e-4bdf-850c-ec68e51f4297_0.pdf",
    sha256: "25f6c83fbe21763bdb7801f4f572120f66c14177da0fa3f04838b811238408f6", bytes: 165241, pages: 8 },
  { file: "senate__Minutes_of_the_49th_Senate_Meeting_Held_on_11_11_2014.pdf", label: "Minutes of the 49th Senate Meeting Held on 11-11-2014", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-49th-senate--held-on-11-11-2014_2280771a-117d-4200-8ccd-04b145bf6b6c_0.pdf",
    sha256: "2a199af3a240d933daa3eab2a89f923f533122729b1b5ef41ab793d1fa6e77e0", bytes: 57737, pages: 9 },
  { file: "senate__Minutes_of_the_48th_Senate_Meeting_Held_on_30_07_2014.pdf", label: "Minutes of the 48th Senate Meeting Held on 30-07-2014", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-48th-senate--held-on-30-07-2014_6b6dd889-afc8-4ba4-a081-aefb72c4d5e9_0.pdf",
    sha256: "783064d8b2426fa00b056031fffbdbdf2ce1576fc24b67310e077f26e4e3e3aa", bytes: 65726, pages: 10 },
  { file: "senate__Minutes_of_the_47th_Senate_Meeting_Held_on_31_03_2014.pdf", label: "Minutes of the 47th Senate Meeting Held on 31-03-2014", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-47th-senate--held-on-31-03-2014_ab71d796-4b83-4f36-a6b8-6bcad4e2bb95_0.pdf",
    sha256: "55eb4144b091fae129344c4f8d14df8c71e5083d7fee61c73417f9a793f4373a", bytes: 37562, pages: 8 },
  { file: "senate__Minutes_of_the_46th_Senate_Meeting_Held_on_11_12_2013.pdf", label: "Minutes of the 46th Senate Meeting Held on 11-12-2013", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-46th-senate--held-on-11-12-2013_e16569f4-6b84-4b2b-908a-d6e4f5102cd8_0.pdf",
    sha256: "fc2a7c120fbd706c29f47fa2dd62a0dfa7e1f5a41d6506a4f08e89da3fe7ab96", bytes: 173918, pages: 11 },
  { file: "fc__Special_Combined_Meeting_of_the_68th_FC_77th_BoG_held_on_14_05_2026.pdf", label: "Special Combined Meeting of the 68th FC & 77th BoG held on 14/05/2026", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/special-combined-meeting-of-the-68th-fc--77th-bog-held-on-14052026_756174e7-82c8-40c9-8db2-a3390979195f_0.pdf",
    sha256: "d619891965b090fa111427c8585ea8825ded447277a59bf168f1b9720bae5690", bytes: 528590, pages: 8 },
  { file: "fc__Minutes_of_the_67th_FC_Meeting_held_on_17_04_2026.pdf", label: "Minutes of the 67th FC Meeting held on 17/04/2026", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-67th-fc-meeting-held-on-17042026_848fc8aa-2fb5-4286-808a-3e4319adfc18_0.pdf",
    sha256: "edcf53e6be0dc68187d8515c1f8a115fe4c972b399db1427f951ff80e6f897ce", bytes: 399823, pages: 16 },
  { file: "fc__Special_Combined_Meeting_of_the_66th_FC_75th_BoG_held_on_11_02_2026.pdf", label: "Special Combined Meeting of the 66th FC & 75th BoG held on 11/02/2026", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/special-combined-meeting-of-the-66th-fc--75th-bog-held-on-11022026_b3b2224c-c64a-4d96-aa6a-894f3f411c3b_0.pdf",
    sha256: "2bcc0e1e7def7ffcc5ddc8610841091c9353f8d5e9cfb1400a1828bd060f378a", bytes: 1941277, pages: 9 },
  { file: "fc__Minutes_of_the_64th_Finance_Committee_Meeting_Held_on_28_03_2025.pdf", label: "Minutes of the 64th Finance Committee Meeting Held on 28/03/2025", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-64th-finance-committee-meeting-held-on-28032025_289_0.pdf",
    sha256: "49164e5f8b57748ebe6d180ea9f7c392159c9bb7b2d3d8f7148dce31acba4242", bytes: 931878, pages: 29 },
  { file: "fc__Minutes_of_the_63rd_Special_Finance_Committee_Meeting_Held_on_13_03_20.pdf", label: "Minutes of the 63rd Special Finance Committee Meeting Held on 13/03/2025", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/--minutes-of-the-63rd-special-finance-committee-meeting-held-on-13032025_286_0.pdf",
    sha256: "625da604d3cffa669f167d35d0b8cebc20761b514954057fbcb7b88cccd12bea", bytes: 339569, pages: 5 },
  { file: "fc__Minutes_of_the_62nd_Finance_Committee_Meeting_Held_on_11_12_2024.pdf", label: "Minutes of the 62nd Finance Committee Meeting Held on 11/12/2024", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-62nd-finance-committee-meeting-held-on-11122024_46b2e796-6892-45c2-a2e7-93e8890a7b04_0.pdf",
    sha256: "b275a0a7dbb06f477c97bd528d5613c12a3ba78851669fc7995748add2950e5a", bytes: 597177, pages: 27 },
  { file: "fc__Minutes_of_the_61st_Finance_Committee_Meeting_Held_on_04_09_2024.pdf", label: "Minutes of the 61st Finance Committee Meeting Held on 04/09/2024", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-61st-finance-committee-meeting-held-on-04092024_255_0.pdf",
    sha256: "b61c312df34b608d689b01c034f8a6fcf76c2203146a753026898df171f8cba0", bytes: 2950530, pages: 46 },
  { file: "fc__Minutes_of_the_60th_Finance_Committee_Meeting_Held_on_15_05_2024.pdf", label: "Minutes of the 60th Finance Committee Meeting Held on 15/05/2024", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-60th-finance-committee-meeting-held-on-15052024_254_0.pdf",
    sha256: "89285d61ccbfd334d0b64eecbe8e11e790a4601f681675c94041657814e7b598", bytes: 1461561, pages: 37 },
  { file: "fc__Minutes_of_the_59th_Finance_Committee_Meeting_Held_on_22_12_2023.pdf", label: "Minutes of the 59th Finance Committee Meeting Held on 22/12/2023", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-59th-finance-committee-meeting-held-on-22122023_253_0.pdf",
    sha256: "686c2d6e20dead84aa7baad76744f0ed65ab816a2095a0e9c9e90efb2468b64c", bytes: 1443019, pages: 19 },
  { file: "fc__Minutes_of_the_58th_Finance_Committee_Meeting_Held_on_01_09_2023.pdf", label: "Minutes of the 58th Finance Committee Meeting Held on 01/09/2023", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-58th-finance-committee-meeting-held-on-01092023_252_0.pdf",
    sha256: "aa3f0b2e0c05f59be048eea1faffd9e2f91d52b3bef15ce5c493bf777f5b666c", bytes: 1502502, pages: 34 },
  { file: "fc__Minutes_of_the_57th_Finance_Committee_Meeting_Held_on_03_07_2023.pdf", label: "Minutes of the 57th Finance Committee Meeting Held on 03/07/2023", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-57th-finance-committee-meeting-held-on-03072023_251_0.pdf",
    sha256: "c83fd7a21ce9978ed8bd18bb03ab9055b4dafc0922c1d6b6a537156e51b028fe", bytes: 594779, pages: 25 },
  { file: "fc__Minutes_of_the_56th_Finance_Committee_Meeting_dated_27_02_2023.pdf", label: "Minutes of the 56th Finance Committee Meeting dated 27/02/2023", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-56th-finance-committee-meeting-dated-27022023_250_0.pdf",
    sha256: "4342070b0e2d8e7707d1bc5f36faa99fd1d3160bdb306b3fc9c89eaa07bcfccc", bytes: 633518, pages: 32 },
  { file: "fc__Minutes_of_the_55th_Finance_Committee_Meeting_Held_on_05_12_2022.pdf", label: "Minutes of the 55th Finance Committee Meeting Held on 05/12/2022", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-55th-finance-committee-meeting-held-on-05122022_3b9bfafe-530d-4e24-a623-61df0e9721fc_0.pdf",
    sha256: "4c56cf052f6b1f76bf8c01389b2d0f1fcf3279c288e22ee7dfd5466c9feb1ceb", bytes: 1276464, pages: 32 },
  { file: "fc__Minutes_of_the_54th_Finance_Committee_Meeting_Held_on_02_09_2022.pdf", label: "Minutes of the 54th Finance Committee Meeting Held on 02/09/2022", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-54th-finance-committee-meeting-held-on-02092022_1047432c-6754-44c2-9a8b-ddd3bc4fc4bf_0.pdf",
    sha256: "91e7ef238916ddf695bdb75c4dd84917878be2381fc6f70316e408cdab1757c6", bytes: 898153, pages: 12 },
  { file: "fc__Minutes_of_the_53rd_Finance_Committee_Meeting_Held_on_07_02_2022.pdf", label: "Minutes of the 53rd Finance Committee Meeting Held on 07/02/2022", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-53rd-meeting-of-the-finance-committee-held-on-07022022_b92c9a4d-bb41-4b94-b1bf-7e8a7191f8c2_0.pdf",
    sha256: "9c464901c9db92c5edb4af9a292c820a1e1e59ffc5631bc3bdcc30147743885a", bytes: 962460, pages: 17 },
  { file: "fc__Minutes_of_the_52nd_Finance_Committee_Meeting_Held_on_06_01_2021.pdf", label: "Minutes of the 52nd Finance Committee Meeting Held on 06/01/2021", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-52-nd-meeting-of-the-fc-held-on-06012021_dd4c2770-3753-4c7f-848c-3c07c1be8592_0.pdf",
    sha256: "717c4359c3166001042207b18772f18563bc02c671f0f26c154a93542216fe5c", bytes: 624636, pages: 7 },
  { file: "fc__Minutes_of_the_51st_Finance_Committee_Meeting_Held_on_30_06_2020.pdf", label: "Minutes of the 51st Finance Committee Meeting Held on 30/06/2020", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-51st-fc-dated-30th-june-2020_5610372e-0dd6-41f2-be8f-c83b633451ea_0.pdf",
    sha256: "33b9e60861ae82021411fa84c8a52daacf3cad941a2c0a42e1532bf24512a0cb", bytes: 338691, pages: 7 },
  { file: "fc__Minutes_of_the_50th_Finance_Committee_Meeting_Held_on_01_02_2020.pdf", label: "Minutes of the 50th Finance Committee Meeting Held on 01/02/2020", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-50th-fc-dated-01st-february-2020_495d1e34-d6b5-41d5-83b3-59a9edf0e62b_0.pdf",
    sha256: "5830e4440423312230404c942b2f59634954011ec972732bf46b9af25324a383", bytes: 333208, pages: 5 },
  { file: "fc__Minutes_of_the_49th_Finance_Committee_Meeting_Held_on_04_11_2019.pdf", label: "Minutes of the 49th Finance Committee Meeting Held on 04/11/2019", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-49th-fc-dated-04th-november-2019_c4872256-2f2b-49d8-96b0-95394fa835f9_0.pdf",
    sha256: "31346e66756627b7844ea6837cb6a7c466f08ee3ab24b33f1a5136592ecb8c60", bytes: 352292, pages: 16 },
  { file: "fc__Minutes_of_the_48th_Finance_Committee_Meeting_Held_on_05_07_2019.pdf", label: "Minutes of the 48th Finance Committee Meeting Held on 05/07/2019", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-48th-finance-committee-meeting-dated-05072019_c671bedf-98c0-473c-8f04-888c66e4897a_0.pdf",
    sha256: "7c0f257f989619619e335b7338743f2502119213fe6d3a8113b623c79c0abc8d", bytes: 567970, pages: 14 },
  { file: "fc__Minutes_of_the_47th_Finance_Committee_Meeting_Held_on_08_05_2019.pdf", label: "Minutes of the 47th Finance Committee Meeting Held on 08/05/2019", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-47th-finance-committee-meeting-dated-08052019_bcf4ae95-e0c8-4a9d-8d8c-b49b46eb8fb9_0.pdf",
    sha256: "86ea9aaf9d7529f0fca3cb3b627f61fd0793701892d9589447635e883ae77fb0", bytes: 228846, pages: 3 },
  { file: "fc__Minutes_of_the_46th_Finance_Committee_Meeting_Held_on_05_02_2019.pdf", label: "Minutes of the 46th Finance Committee Meeting Held on 05/02/2019", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-46th-finance-committee-meeting-dated-05022019_d54d2645-e595-4b0e-bf6e-2202a2c0ad8b_0.pdf",
    sha256: "89206ec6b36d1aa40f9282ab805305eb8d700f6c054716fbbd45de453bc3166e", bytes: 217798, pages: 8 },
  { file: "fc__Minutes_of_the_45th_Finance_Committee_Meeting_Held_on_12_10_2018.pdf", label: "Minutes of the 45th Finance Committee Meeting Held on 12/10/2018", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-45th-finance-committee-meeting-dated-12102018_9d2ac2fc-39bc-4c52-bee8-804aacb0a9cb_0.pdf",
    sha256: "2f9f0a2291cd6071c284a8da7640c0381a759f6e3165f09fcdb7ab251e4eb5f7", bytes: 183378, pages: 4 },
  { file: "fc__Minutes_of_the_44th_Finance_Committee_Meeting_Held_on_05_09_2018.pdf", label: "Minutes of the 44th Finance Committee Meeting Held on 05/09/2018", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-44th-finance-committee-meeting-dated-05092018_0aca3bea-8ce7-4000-9dc0-03e6d6c4c727_0.pdf",
    sha256: "15506e33fc4f0e5250df31bf6d3a6dec3be39657fa309a4512b04118519a30b8", bytes: 203208, pages: 4 },
  { file: "fc__Minutes_of_the_43rd_Finance_Committee_Meeting_Held_on_20_06_2018.pdf", label: "Minutes of the 43rd Finance Committee Meeting Held on 20/06/2018", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-43rd-finance-committee-meeting_4830c9aa-18d8-4e1f-b0c0-ab0606ffd2d7_0.pdf",
    sha256: "bd2960e54cf0948065baf9dd674f2a7bda3fd9fa0fe495a704fffce4fbe62b14", bytes: 327170, pages: 4 },
  { file: "fc__Minutes_of_the_42nd_Finance_Committee_Meeting_Held_on_19_03_2018.pdf", label: "Minutes of the 42nd Finance Committee Meeting Held on 19/03/2018", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-42nd-finance-committee-meeting_3b7c13a8-a901-47e9-b8ab-76f4d057c5d6_0.pdf",
    sha256: "ff77a2fe91b0de87cf574345bad66104a2435ce6749d73801c34a811dc1a06d8", bytes: 679649, pages: 7 },
  { file: "fc__Minutes_of_the_41st_Finance_Committee_Meeting_Held_on_22_12_2017.pdf", label: "Minutes of the 41st Finance Committee Meeting Held on 22/12/2017", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-41st-finance-committee-meeting_d6fbc79c-b274-46bf-8c49-20f6640924d2_0.pdf",
    sha256: "47158c4326a1c756f0eb4ea8fe51a93af44914273dbeb61f640663b03f1ccf8b", bytes: 238637, pages: 3 },
  { file: "fc__Minutes_of_the_40th_Finance_Committee_Meeting_Held_on_30_10_2017.pdf", label: "Minutes of the 40th Finance Committee Meeting Held on 30/10/2017", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-40th-finance-committee-meeting_b9ef0f25-77b6-4a73-9e9d-39e177fed600_0.pdf",
    sha256: "49eea5ad67633a1affc3636eeb24fd9bc188e53b332a688109d5f24612f43884", bytes: 461937, pages: 8 },
  { file: "fc__Minutes_of_the_39th_Finance_Committee_Meeting_Held_on_31_07_2017.pdf", label: "Minutes of the 39th Finance Committee Meeting Held on 31/07/2017", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-39th-finance-committee-meeting_a9f4459a-f8c9-44da-840d-37e676b4b5ac_0.pdf",
    sha256: "90fc97bc502dc9fa9850a7bb01bac5e06d807b6b1890b8f27e7fdd8062eb3876", bytes: 67019, pages: 7 },
  { file: "fc__Minutes_of_the_38th_Finance_Committee_Meeting_Held_on_22_04_2017.pdf", label: "Minutes of the 38th Finance Committee Meeting Held on 22/04/2017", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-38th-finance-committee-meeting_1d7c4451-3a5c-4260-a8a0-56de50692011_0.pdf",
    sha256: "a4d772824b80557c73cb038673562d305187488518b9d6dc89f1ba3ec7e47018", bytes: 73217, pages: 5 },
  { file: "fc__Minutes_of_the_37th_Finance_Committee_Meeting_Held_on_30_03_2017.pdf", label: "Minutes of the 37th Finance Committee Meeting Held on 30/03/2017", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-37th-finance-committee-meeting_0c4d6d07-4aa1-4bad-a07f-b84d99924e96_0.pdf",
    sha256: "18a326ae873c1d828e6d2e675644496f594565c906c3d58c8aec962764116178", bytes: 109068, pages: 4 },
  { file: "fc__Minutes_of_the_36th_Finance_Committee_Meeting_Held_on_13_02_2017.pdf", label: "Minutes of the 36th Finance Committee Meeting Held on 13/02/2017", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-36th-finance-committee-meeting_da0815fb-27b9-4197-b0b4-ad428530c25d_0.pdf",
    sha256: "b6d1981123afee3664268841bdf2fbe5db8bd1be8dcb3a89305eed0f24422a3f", bytes: 316075, pages: 3 },
  { file: "fc__Minutes_of_the_35th_Finance_Committee_Meeting_Held_on_21_11_2016.pdf", label: "Minutes of the 35th Finance Committee Meeting Held on 21/11/2016", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-35th-finance-committee-meeting_f7cfc276-2f42-4320-875d-af66d9b65fe9_0.pdf",
    sha256: "f80b366f05a5b1730bfbae8c2d61fc28bcf23ad1791e17f86ee1a8a87b51b949", bytes: 422516, pages: 3 },
  { file: "fc__Minutes_of_the_34th_Finance_Committee_Meeting_Held_on_09_08_2016.pdf", label: "Minutes of the 34th Finance Committee Meeting Held on 09/08/2016", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-34th-finance-committee-meeting_90e0d3c1-4645-45b8-b094-2575bbf68630_0.pdf",
    sha256: "3506d4c936fbf0ee6ed4dd8a73cea08e6937b37882d08de0088732c3193eade5", bytes: 293222, pages: 3 },
  { file: "fc__Minutes_of_the_33rd_Finance_Committee_Meeting_Held_on_02_05_2016.pdf", label: "Minutes of the 33rd Finance Committee Meeting Held on 02/05/2016", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-33rd-finance-committee-meeting_53e6a5cf-151b-441c-8e67-e2577c3f671d_0.pdf",
    sha256: "8e7a3c0b5e7e2459c4888126780cc2a2eb08ea84f254bfca2012d51c0201c6d9", bytes: 398229, pages: 3 },
  { file: "fc__Minutes_of_the_32nd_Finance_Committee_Meeting_Held_on_05_02_2016.pdf", label: "Minutes of the 32nd Finance Committee Meeting Held on 05/02/2016", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-32nd-finance-committee-meeting_fd59bc6f-69b9-4b74-ac0e-d590456365ab_0.pdf",
    sha256: "e3f7590fcd55ad302daa86fad46e2ce465753474770d3a91956daeb11259ff5e", bytes: 400313, pages: 4 },
  { file: "fc__Minutes_of_the_31st_Finance_Committee_Meeting_Held_on_21_11_2015.pdf", label: "Minutes of the 31st Finance Committee Meeting Held on 21/11/2015", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-31st-finance-committee-meeting_78f5eab7-7123-4f49-afd3-8efd5ce5e0d6_0.pdf",
    sha256: "5524b1fca48f922114b47114e7819b2f501da49ed48ed57f10e527d9bbecc975", bytes: 409644, pages: 6 },
  { file: "fc__Minutes_of_the_30th_Finance_Committee_Meeting_Held_on_09_01_2015.pdf", label: "Minutes of the 30th Finance Committee Meeting Held on 09/01/2015", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-30th-finance-committee-meeting_904fa84d-8305-49de-b9ae-fa40d3ec8aad_0.pdf",
    sha256: "1b7e921dfb8241ed1e5bcab703bcaf3b61668d3a59a64bdc28b111012c502eec", bytes: 102073, pages: 4 },
  { file: "fc__Minutes_of_the_29th_Finance_Committee_Meeting_Held_on_07_05_2014.pdf", label: "Minutes of the 29th Finance Committee Meeting Held on 07/05/2014", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-29th-finance-committee-meeting_f45ad77b-c757-4bd9-965e-0feebaf7a01d_0.pdf",
    sha256: "dcf332cf5faa51a6746dc3c8944c5c05fc16df44351dcfa3e8af680dfb62a33e", bytes: 25884, pages: 3 },
  { file: "fc__Minutes_of_the_28th_Finance_Committee_Meeting_Held_on_28_03_2014.pdf", label: "Minutes of the 28th Finance Committee Meeting Held on 28/03/2014", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-28th-finance-committee-meeting_10c4bd8e-2b39-44ff-8ad9-740815bec9d5_0.pdf",
    sha256: "ed497a97e439aa035305b68768cc4036deefc42f31aa6e2710ba963b549b4879", bytes: 137830, pages: 9 },
  { file: "fc__Minutes_of_the_27th_Finance_Committee_Meeting_Held_on_22_10_2013.pdf", label: "Minutes of the 27th Finance Committee Meeting Held on 22/10/2013", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-27th-finance-committee-meeting_937f2d50-1a3a-4fdf-9e44-6e35251923eb_0.pdf",
    sha256: "3a9f53ab12a34de6fa401d5f6f10164345c72523e7a1e96f3173e619c72f7318", bytes: 37799, pages: 6 },
  { file: "fc__Minutes_of_the_26th_Finance_Committee_Meeting_Held_on_24_07_2013.pdf", label: "Minutes of the 26th Finance Committee Meeting Held on 24/07/2013", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-26th-finance-committee-meeting_d14e7f79-1a67-4952-876c-8814d1ea1b3a_0.pdf",
    sha256: "84906219d6d63ccc815d488d0b0ebb625bc0ba1bb3fb70dd428c6e90f86188ec", bytes: 135035, pages: 9 },
  { file: "fc__Minutes_of_the_25th_Finance_Committee_Meeting_Held_on_27_04_2013.pdf", label: "Minutes of the 25th Finance Committee Meeting Held on 27/04/2013", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-25th-finance-committee-meeting_414cf6ac-fce7-4476-aaa1-18a96f3724d9_0.pdf",
    sha256: "66068a2df67d200c884251b66cacd78aa078d5ca5610349878b5fac7eb7a5b2a", bytes: 114733, pages: 7 },
  { file: "fc__Minutes_of_the_24th_Finance_Committee_Meeting_Held_on_03_01_2013.pdf", label: "Minutes of the 24th Finance Committee Meeting Held on 03/01/2013", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-24th-finance-committee-meeting_77cf45a6-cbc7-4e84-a1dc-2df853e88b05_0.pdf",
    sha256: "6885ba0f8842572dca3dfa8a748295ce7544abba4c72c3cf09c38d273582882a", bytes: 43937, pages: 4 },
  { file: "fc__Minutes_of_the_23rd_Finance_Committee_Meeting_Held_on_16_10_2012.pdf", label: "Minutes of the 23rd Finance Committee Meeting Held on 16/10/2012", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-23rd-finance-committee-meeting_23a92656-6c5d-45d1-8130-05d2c52b8929_0.pdf",
    sha256: "2f72dbfaf585f9254b6dfb41dd98a6a1747634ddedda3f8eca7667418e047a67", bytes: 65427, pages: 7 },
  { file: "fc__Minutes_of_the_22nd_Finance_Committee_Meeting_Held_on_16_05_2012.pdf", label: "Minutes of the 22nd Finance Committee Meeting Held on 16/05/2012", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-22nd-finance-committee_498b2ada-f09c-42a9-960e-a70b0ebc60e7_0.pdf",
    sha256: "7bbf60badcfe61b695c22b899eb1dc324cb125b527fa07114c5d86831b059912", bytes: 71066, pages: 2 },
  { file: "fc__Minutes_of_the_21st_Finance_Committee_Meeting_Held_on_03_05_2012.pdf", label: "Minutes of the 21st Finance Committee Meeting Held on 03/05/2012", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-21st-finance-committee_26ae77cc-159d-4ba6-be68-780135dde288_0.pdf",
    sha256: "7a7c07ed0d2072b79f10fde80e8b6213ad4bd73cb260bdd5e3df51102800711d", bytes: 75107, pages: 2 },
  { file: "fc__Minutes_of_the_20th_Finance_Committee_Meeting_Held_on_18_01_2012.pdf", label: "Minutes of the 20th Finance Committee Meeting Held on 18/01/2012", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-20th-finance-committee_f63d907a-9116-4169-84a4-3d962b5190fa_0.pdf",
    sha256: "83b252df1267abcc912ae9448630e6c66990b70f352435369724cba9ae83a681", bytes: 81023, pages: 8 },
  { file: "fc__Minutes_of_the_19th_Finance_Committee_Meeting_Held_on_31_08_2011.pdf", label: "Minutes of the 19th Finance Committee Meeting Held on 31/08/2011", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/minutes-of-the-19th-finance-committee_b3a42550-c48a-4022-a842-b4e186a5cb0d_0.pdf",
    sha256: "8c6f58ae573abc5f4581adfb57909e0429087a14d62f7b8e4c9cfc6c3147dce0", bytes: 1103048, pages: 5 },
  { file: "bwc__BWC_Meeting_2026_01.pdf", label: "BWC Meeting (2026:01)", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/bwc-meeting-202601_7d4ddec5-e8fe-443a-826a-b58524c6ebd4_0.pdf",
    sha256: "7324bcf31ec948f714f9d344df235630d39b77fddd0a531f7a3805e6f950ede1", bytes: 7776677, pages: 21 },
  { file: "bwc__BWC_Meeting_2025_03.pdf", label: "BWC Meeting (2025:03)", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/bwc-meeting-202503_331_0.pdf",
    sha256: "922c84d16b4ec4c5c0ab86eaf1cbf7deafbfdcf80a93a7a920610d70f6561d31", bytes: 705096, pages: 25 },
  { file: "bwc__BWC_Meeting_2025_02.pdf", label: "BWC Meeting (2025:02)", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/-bwc-meeting-202502_300_0.pdf",
    sha256: "7961cc31bde274fbf0ab0cad6a171ce622754d02623ac5e2db3db334c7ef8abe", bytes: 6675695, pages: 22 },
  { file: "bwc__BWC_Meeting_2025_01.pdf", label: "BWC Meeting (2025:01)", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/-bwc-meeting-202501_c98bd7ce-31f5-41f3-a841-5d25502ca763_0.pdf",
    sha256: "d010e2591163c429d67c82a8ab33753fa3ab95a20cebc41d41f9af12c3b1c25c", bytes: 654402, pages: 14 },
  { file: "bwc__BWC_Meeting_2024_04.pdf", label: "BWC Meeting (2024:04)", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/bwc-meeting-202404_a6f01a20-3a18-4387-95ff-94aff0f268fe_0.pdf",
    sha256: "25279a9085b8ecc4d90bd86c6b4aa214bbece1fa35650d5c575da35ba50de96d", bytes: 188288, pages: 8 },
  { file: "bwc__BWC_Meeting_2024_03.pdf", label: "BWC Meeting (2024:03)", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/bwc-meeting-202403_1611ec6a-1bbb-498f-b3ab-278ddd69ebb2_0.pdf",
    sha256: "b53b7bbd111da4ceb418614f7df9f587d8b8777316a1322fd3236fa7ec8eea2e", bytes: 710711, pages: 10 },
  { file: "bwc__BWC_Meeting_2024_02.pdf", label: "BWC Meeting (2024:02)", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/bwc-meeting-202402_f55fe4ae-7e6c-4c2c-a4fc-99d33a7fb68e_0.pdf",
    sha256: "f29d700ac99fa0f9cd86e5ce96b0a3bc00734f53101c4b82946d3c349ac4ee5b", bytes: 721832, pages: 10 },
  { file: "bwc__BWC_Meeting_2023_03.pdf", label: "BWC Meeting (2023:03)", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/bwc-meeting-202303_216b4e86-3b3d-4f0e-8aa9-e30cce4fc01b_0.pdf",
    sha256: "c429a57ba37bb1d72e898eaaa9068015f5d3748815c74a03a92de68ee6c30d7d", bytes: 4619019, pages: 9 },
  { file: "bwc__BWC_Meeting_2023_02.pdf", label: "BWC Meeting (2023:02)", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/bwc-meeting-202302_d758f0b2-af84-47db-a5ef-3f34bb58f589_0.pdf",
    sha256: "fc7d1e69518159ce260dc4f5482940f0d4be1a4b15f1bd668bf0160adc305d6b", bytes: 3459718, pages: 19 },
  { file: "bwc__BWC_Meeting_2023_01.pdf", label: "BWC Meeting (2023:01)", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/bwc-meeting-202301_b85af159-20c7-4a63-ab9e-d65ac9b6fba9_0.pdf",
    sha256: "00a1f3bd0c84ca0843ce7c1c7b022bbc98ed99312581053dbc9768ff01c2664e", bytes: 4514528, pages: 9 },
  { file: "bwc__BWC_Meeting_2022_02.pdf", label: "BWC Meeting (2022:02)", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/bwc-meeting-202202_2378dab7-41be-4eda-8634-c4272d7526b9_0.pdf",
    sha256: "cfba1c0c003dbd32073fd08fd42dd469314bc0d595fe52adeae2a9ff9fd7e0a2", bytes: 1229443, pages: 22 },
  { file: "bwc__BWC_Meeting_2022_01.pdf", label: "BWC Meeting (2022:01)", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/bwc-meeting-202201_c249d40f-a99f-4fa7-a8c1-34878e4f2ff0_0.pdf",
    sha256: "d883a7d0d6fea4ef09c49cbc174291b1b486c34f03d42de1c99b7cb927e7d09c", bytes: 1211840, pages: 15 },
  { file: "bwc__BWC_Meeting_2021_01.pdf", label: "BWC Meeting (2021:01)", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/bwc-meeting-202101_28c8df56-b3bb-4116-a552-67b73ff17730_0.pdf",
    sha256: "2f0678ee8a6939a47965f004012507775a9ef3cfb3f1adcfceae8980de65c19c", bytes: 1944521, pages: 26 },
  { file: "annual__Annual_Report_2024_2025_Hindi.pdf", label: "Annual Report 2024 - 2025 (Hindi)", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/annual-report-2024---2025-hindi_95352342-76e6-4a9e-91e7-0f507bd7bbdc_0.pdf",
    sha256: "77a8b3ae639aab2a4fe1f217e1939644ce34a89ff518953e704129b82ea37b25", bytes: 19105842, pages: 220 },
  { file: "annual__Annual_Report_2024_2025_English.pdf", label: "Annual Report 2024 - 2025 (English)", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/annual-report-2024---2025-english_7dfa173a-c519-443c-aaf7-bf6a8776742d_0.pdf",
    sha256: "3a7be2549026a739549f6ce2f0309d0fc53b74b3001e9ea02feb0e55f8879d1a", bytes: 20261840, pages: 224 },
  { file: "annual__Annual_Report_2023_2024_Hindi.pdf", label: "Annual Report 2023 - 2024 (Hindi)", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/annual-report-2023---2024-hindi_f23ab1d2-33cc-4f46-ad37-72c1ae03318c_0.pdf",
    sha256: "1b2a48b51aa11f393861ec880d216aa2fd841e91a5243aedccb6061b8cc21886", bytes: 58371009, pages: 176 },
  { file: "annual__Annual_Report_2023_2024_English.pdf", label: "Annual Report 2023 - 2024 (English)", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/annual-report-2023---2024-english_b056945b-44e5-4565-a15f-8bcb11d8882e_0.pdf",
    sha256: "4ee62a2e6d623a241e29d231c9cd9e56c3ebdb642a98cd8e5cff58261c5ae076", bytes: 33430244, pages: 164 },
  { file: "annual__Annual_Report_Annual_Accounts_2022_2023_Hindi.pdf", label: "Annual Report & Annual Accounts 2022 – 2023 (Hindi)", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/annual-report--annual-accounts-2022--2023-hindi_f40d4e76-c199-47cd-bef6-406eb025efe6_0.pdf",
    sha256: "021207660f7387f11ac143772bdf54c5ed3a5132f26aef3b561cfad1a0a3a4e0", bytes: 4731388, pages: 328 },
  { file: "annual__Annual_Report_Annual_Accounts_2022_2023_English.pdf", label: "Annual Report & Annual Accounts 2022 - 2023 (English)", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/annual-report--annual-accounts-2022---2023-english_82b63c5f-7360-4f5c-aa61-0b8c616a07c0_0.pdf",
    sha256: "1f5a2913ed14935977a29a2b7a87fc2a9fd6f38f24a38b90d3db3170fb58cff4", bytes: 16157721, pages: 300 },
  { file: "annual__Annual_Report_Annual_Accounts_2021_2022_Hindi.pdf", label: "Annual Report & Annual Accounts 2021 - 2022 (Hindi)", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/annual-report--annual-accounts-2021---2022-hindi_ef7f7948-3f49-402f-a51e-85e4a5c94dfc_0.pdf",
    sha256: "c1b11a2d2dfc9ac99f73f6bae8f88ec2bf7be407d0c6ff2c3ed683d5404e8de5", bytes: 8023135, pages: 329 },
  { file: "annual__Annual_Report_Annual_Accounts_2021_2022_English.pdf", label: "Annual Report & Annual Accounts 2021 - 2022 (English)", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/annual-report--annual-accounts-2021---2022-english_6d601f8f-ee4c-45e6-975a-51a4d2e91916_0.pdf",
    sha256: "d3624ebdd43145b8b9a8f18b230dc4e906877d43f8986d921fe07d05052ff45e", bytes: 17643332, pages: 341 },
  { file: "annual__Annual_Report_Annual_Accounts_2020_2021_Hindi.pdf", label: "Annual Report & Annual Accounts 2020 - 2021 ( Hindi)", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/annual-report--annual-accounts-2020---2021--hindi_548ec5dc-ae94-4ec9-9362-d584aae54b6d_0.pdf",
    sha256: "ca881d7b6aa9739c87be421c5deded3019281bb74e0dde472a96dfac067238d3", bytes: 18354903, pages: 473 },
  { file: "annual__Annual_Report_Annual_Accounts_2020_2021_English.pdf", label: "Annual Report & Annual Accounts 2020 - 2021 (English)", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/annual-report--annual-accounts-2020---2021-english_2fedabaa-04c2-4698-9133-572c414b457a_0.pdf",
    sha256: "52e234efd80858b68fbe267771e2cfb981b7dcd61f10423d2b1b03e6730b9f7d", bytes: 17666502, pages: 337 },
  { file: "annual__Annual_Report_Annual_Accounts_2019_2020_Hindi.pdf", label: "Annual Report & Annual Accounts 2019 - 2020 (Hindi)", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/annual-report--annual-accounts-2019---2020-hindi_a4aedc44-7468-4a5e-a395-4c7f275ad7cf_0.pdf",
    sha256: "10fa581e9b88b07e9ee3ed465c2388964ce68b8005cb83ffede293d1d1d79fd4", bytes: 16796816, pages: 629 },
  { file: "annual__Annual_Report_Annual_Accounts_2019_2020_English.pdf", label: "Annual Report & Annual Accounts 2019 - 2020 (English)", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/annual-report--annual-accounts-2019---2020-english_2516aec0-8ef0-4413-85e5-9bf480c9bfa3_0.pdf",
    sha256: "1940afdb7e858a19b1307946e28f35aa598756ff9c01b3a8500d54a0cacf84df", bytes: 10477412, pages: 479 },
  { file: "annual__Annual_Report_Annual_Accounts_2018_2019.pdf", label: "Annual Report & Annual Accounts 2018 - 2019", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/annual-report--annual-accounts-2018---2019_61ff1565-c169-45df-a0c8-a7adefe18aab_0.pdf",
    sha256: "e673709a32f45bf928cffc167e8e5f10eaed135dc94d0859c97558160be41188", bytes: 13054937, pages: 464 },
  { file: "annual__Annual_Report_Annual_Accounts_2017_2018.pdf", label: "Annual Report & Annual Accounts 2017 - 2018", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/annual-report-and-annual-accounts-2017-2018_53a97f9f-b84e-4558-80f4-59e9e62ff1b8_0.pdf",
    sha256: "1c9adc878264145d65597e95cb40a7417cca2565e83ab8fabfc600af39be708a", bytes: 39692367, pages: 382 },
  { file: "annual__Annual_Report_Annual_Accounts_2016_2017.pdf", label: "Annual Report & Annual Accounts 2016 - 2017", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/annual-report--annual-accounts-2016--17_d0150c5f-7df1-4361-952b-18272e45b88b_0.pdf",
    sha256: "5abc9e7e82d73e19df497d1fccd5492116f8acc25e175be61caf6f3c599537dc", bytes: 61648694, pages: 314 },
  { file: "annual__Annual_Report_2015_2016.pdf", label: "Annual Report 2015 - 2016", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/annual-report-2015--16_63ffa247-d3dd-4a68-b576-2b1ea3103dd2_0.pdf",
    sha256: "9886831807bb68027e4816092b3ffbbf54d99cd0779f9e78fd6613a2853f66ef", bytes: 2644726, pages: 170 },
  { file: "annual__Annual_Accounts_2015_2016.pdf", label: "Annual Accounts 2015 - 2016", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/annual-accounts-2015-16_e4daf115-4fd9-4b0d-b43d-527aca8d56c2_0.pdf",
    sha256: "4055fe408d6ce5d3e7a7dc1e9497aa7f32dbfacce46d46041cb8ba2396368546", bytes: 2046696, pages: 86 },
  { file: "annual__Annual_Report_Annual_Accounts_2014_2015.pdf", label: "Annual Report & Annual Accounts 2014 - 2015", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/annual-report-2014-15_4a30a25f-e345-40e6-900d-f85d1d595cd5_0.pdf",
    sha256: "0dff66adf4829c735a4e158e006526a9bf152b5542115f1971c8b13688faffab", bytes: 3238785, pages: 262 },
  { file: "annual__Annual_Report_2013_2014.pdf", label: "Annual Report 2013 - 2014", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/annual-report-2013-14_5a7be477-97d2-4461-9005-064b50431873_0.pdf",
    sha256: "c80c4f94d5d615abd887f766166dda3971f8d8bd98eb4883ddfa4e2b1680e2b9", bytes: 1998461, pages: 204 },
  { file: "annual__Annual_Accounts_2013_2014.pdf", label: "Annual Accounts 2013 - 2014", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/annual-accounts-2013-14_b48ff39a-49ea-4fb4-9bb4-57a2eb3afff4_0.pdf",
    sha256: "8a4f0d90474e2a30b2317e6d4ece106a05bb0090ac2471b45d434d8993bfdbc2", bytes: 1846378, pages: 34 },
  { file: "annual__Audit_Certificate_Audit_Report_2012_2013.pdf", label: "Audit Certificate & Audit Report 2012-2013", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/audit-certificate-and-audit-report-2012-2013_ef8fff1d-89af-4e81-a3fc-3f5e6dcc2c91_0.pdf",
    sha256: "9717a065535dcd27b5fbee320f5a35061628bc2fc66818139eb64ed1577aabcf", bytes: 828778, pages: 3 },
  { file: "annual__Annual_Report_2012_2013.pdf", label: "Annual Report 2012 - 2013", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/annual-report-2012-13_f592d8fe-fc82-4bf3-ac69-2b15b6f52896_0.pdf",
    sha256: "33e40656f7d769ca21b5ca482f99fcf8a2e82c3de369177c99bdfa50210cf882", bytes: 6220520, pages: 168 },
  { file: "annual__Annual_Accounts_2012_2013.pdf", label: "Annual Accounts 2012 - 2013", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/annual-accounts-2012-13_831ac3fd-cf85-4278-a3cb-f2f6e3e24e5b_0.pdf",
    sha256: "e3b91e6c91687783621ad180284582f6d082d9a1b4d1201a3fb32ca5d03fb8af", bytes: 498016, pages: 25 },
  { file: "annual__Annual_Report_2011_2012.pdf", label: "Annual Report 2011 - 2012", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/annual-report-2011-12_b8eee557-329b-40bb-b990-9b8083ff3a2d_0.pdf",
    sha256: "98d024a74edab695251897821399c7d7c902976a63c8caeba833ebc2d6c7dfca", bytes: 1117015, pages: 146 },
  { file: "annual__Annual_Accounts_2011_2012.pdf", label: "Annual Accounts 2011 - 2012", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/annual-accounts-2011-12_969cebac-7f4c-444a-aecf-069436ae3ce2_0.pdf",
    sha256: "c58a8c00dafc84d724e77636920ac47a966974388e2507e5568ebdf4f7de5374", bytes: 3369825, pages: 24 },
  { file: "convocation__20th_Convocation_Report.pdf", label: "20th Convocation Report", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/-20th-convocation-report_90bcf4b5-477e-4780-bc82-51f6cb968bfe_0.pdf",
    sha256: "6893b75a6d684f33dccdc7a7786eeb4aa9b3505bbfca14b4f3954e64b7f0f0b6", bytes: 19034384, pages: 119 },
  { file: "convocation__19th_Convocation_Report.pdf", label: "19th Convocation Report", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/19th-convocation-report_235_0.pdf",
    sha256: "73704e03b1ba472e3d7260fdee20e4da46e13dfbc98afc0e0296b22299c04fd0", bytes: 9156293, pages: 128 },
  { file: "convocation__18th_Convocation_Report.pdf", label: "18th Convocation Report", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/18th_43a64a83-c277-4660-9dab-138ddb723898_0.pdf",
    sha256: "63070f9ddc80679672b7e13a4236c58d72816a89a1e6c36487cd3f07e7bc8578", bytes: 5852077, pages: 114 },
  { file: "convocation__17th_Convocation_Report.pdf", label: "17th Convocation Report", kind: "minutes", url: "https://nitc.ac.in/imgserver/uploads/attachments/17th-convocation-report_467535e5-4433-4803-af1d-b6084fe6c1d9_0.pdf",
    sha256: "fbd04e2ac35004928c63fff8985a67ae9a453806a8b176892aa5a06c6040851b", bytes: 16007200, pages: 92 },
].freeze

# Links that existed when the archive was built but now redirect to the site
# root. Kept here so the gap is documented rather than forgotten.
DEAD = {
  "acts__students_conduct_and_disciplinary_code_2022.pdf" => [
    "https://nitc.ac.in/imgserver/uploads/attachments/students-conduct-and-disciplinary-code-2022_b5a56f11-878a-4c54-b2da-4c552fa8f6c0_0.pdf",
    "students conduct and disciplinary code 2022",
  ],
}.freeze

MAX_REDIRECTS = 5
RETRIES = 3

def human(bytes)
  return "0 B" if bytes.nil? || bytes.zero?
  units = %w[B KB MB GB]
  i = 0
  n = bytes.to_f
  while n >= 1024 && i < units.size - 1
    n /= 1024.0
    i += 1
  end
  format(i.zero? ? "%d %s" : "%.1f %s", n, units[i])
end

def sha256(path)
  Digest::SHA256.file(path).hexdigest
end

def fetch(uri_str, limit = MAX_REDIRECTS)
  raise "too many redirects" if limit.zero?

  uri = URI.parse(uri_str)
  raise "not http(s): #{uri_str}" unless %w[http https].include?(uri.scheme)

  res = nil
  RETRIES.times do |attempt|
    begin
      res = Net::HTTP.start(uri.host, uri.port,
                            use_ssl: uri.scheme == "https",
                            open_timeout: 30, read_timeout: 120) do |http|
        req = Net::HTTP::Get.new(uri)
        req["User-Agent"] = "Mozilla/5.0 (compatible; nitc-source-fetch/1.0)"
        req["Referer"] = "https://nitc.ac.in/"
        req["Accept"] = "application/pdf,*/*"
        http.request(req)
      end
      break
    rescue StandardError => e
      raise e if attempt == RETRIES - 1
      sleep(1.5 * (attempt + 1))
    end
  end

  case res
  when Net::HTTPSuccess
    res.body
  when Net::HTTPRedirection
    fetch(URI.join(uri_str, res["location"]).to_s, limit - 1)
  else
    raise "HTTP #{res.code} #{res.message}"
  end
end

def looks_like_html?(body)
  head = body[0, 512].to_s
  head.include?("<!DOCTYPE html") || head.include?("<html")
end

options = { force: false, verify: false, list: false, dest: File.expand_path("../../research/raw/sources", __dir__) }

OptionParser.new do |o|
  o.banner = "usage: ruby fetch_sources.rb [options]"
  o.on("--force", "re-download files that already exist") { options[:force] = true }
  o.on("--verify", "verify existing files, download nothing") { options[:verify] = true }
  o.on("--list", "print the manifest and exit") { options[:list] = true }
  o.on("--dest DIR", "destination root (default: this directory)") { |d| options[:dest] = d }
end.parse!

if options[:list]
  DOCS.each do |d|
    puts format("%-72s %8s %4s p  %s", d[:file], human(d[:bytes]), d[:pages] || "?", d[:url])
  end
  DEAD.each { |f, (u, l)| puts format("%-72s %8s      %s", f, "DEAD", u) }
  exit 0
end

FileUtils.mkdir_p(File.join(options[:dest], "rti", "files"))
FileUtils.mkdir_p(File.join(options[:dest], "minutes", "files"))

ok = 0
skipped = 0
failed = []
changed = []

DOCS.each do |doc|
  sub  = doc[:kind] == "rti" ? File.join("rti", "files") : File.join("minutes", "files")
  path = File.join(options[:dest], sub, doc[:file])

  if File.exist?(path) && !options[:force]
    if sha256(path) == doc[:sha256]
      skipped += 1
      puts "cached   #{doc[:file]}"
      next
    elsif options[:verify]
      changed << doc[:file]
      puts "CHANGED  #{doc[:file]}"
      next
    else
      puts "stale    #{doc[:file]} (sha mismatch, re-fetching)"
    end
  elsif options[:verify]
    changed << doc[:file]
    puts "MISSING  #{doc[:file]}"
    next
  end

  tmp = "#{path}.part"
  begin
    body = fetch(doc[:url])
    raise "server returned HTML, link is dead or moved" if looks_like_html?(body)
    raise "short read (#{body.bytesize} bytes)" if body.bytesize.zero?

    File.binwrite(tmp, body)
    got = sha256(tmp)
    if got != doc[:sha256]
      FileUtils.mv(tmp, "#{path}.unverified")
      raise "sha256 mismatch: expected #{doc[:sha256][0, 12]}… got #{got[0, 12]}… (saved as .unverified)"
    end

    FileUtils.mv(tmp, path)
    ok += 1
    puts "fetched  #{doc[:file]} (#{human(body.bytesize)})"
  rescue StandardError => e
    FileUtils.rm_f(tmp)
    failed << [doc[:file], e.message]
    puts "FAILED   #{doc[:file]}: #{e.message}"
  end
end

puts
puts "---"
puts "#{ok} fetched, #{skipped} cached#{options[:verify] ? ", #{changed.size} differing/missing" : ""}, #{failed.size} failed"

unless DEAD.empty?
  puts
  puts "Known dead at archive time (not errors):"
  DEAD.each { |f, (u, l)| puts "  #{l}\n    #{u}\n    -> re-check manually; may need an RTI request" }
end

if failed.any?
  puts
  puts "Failures:"
  failed.each { |f, m| puts "  #{f}: #{m}" }
  exit 1
end

exit(changed.any? ? 1 : 0)
__END__
