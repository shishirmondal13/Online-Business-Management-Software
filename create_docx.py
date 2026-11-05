import docx
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml import OxmlElement
from docx.oxml.ns import qn

def create_element(name):
    return OxmlElement(name)

def add_page_number(run):
    fldChar1 = create_element('w:fldChar')
    fldChar1.set(qn('w:fldCharType'), 'begin')
    instrText = create_element('w:instrText')
    instrText.set(qn('xml:space'), 'preserve')
    instrText.text = "PAGE"
    fldChar2 = create_element('w:fldChar')
    fldChar2.set(qn('w:fldCharType'), 'separate')
    fldChar3 = create_element('w:fldChar')
    fldChar3.set(qn('w:fldCharType'), 'end')
    
    r = run._r
    r.append(fldChar1)
    r.append(instrText)
    r.append(fldChar2)
    r.append(fldChar3)

def set_cell_background(cell, fill_hex):
    tcPr = cell._element.get_or_add_tcPr()
    shd = create_element('w:shd')
    shd.set(qn('w:val'), 'clear')
    shd.set(qn('w:color'), 'auto')
    shd.set(qn('w:fill'), fill_hex)
    tcPr.append(shd)

def set_cell_margins(cell, top=100, bottom=100, left=150, right=150):
    tcPr = cell._element.get_or_add_tcPr()
    tcMar = create_element('w:tcMar')
    for m, val in [('top', top), ('bottom', bottom), ('left', left), ('right', right)]:
        node = create_element(f'w:{m}')
        node.set(qn('w:w'), str(val))
        node.set(qn('w:type'), 'dxa')
        tcMar.append(node)
    tcPr.append(tcMar)

def build_docx():
    doc = docx.Document()
    
    # Page setup
    for section in doc.sections:
        section.top_margin = Inches(0.8)
        section.bottom_margin = Inches(0.8)
        section.left_margin = Inches(0.8)
        section.right_margin = Inches(0.8)
        
        # Header
        header = section.header
        hp = header.paragraphs[0]
        hp.alignment = WD_ALIGN_PARAGRAPH.RIGHT
        hrun = hp.add_run("Smart Buy Online (I-Buzz BD) — Financial & Business Calculations")
        hrun.font.name = "Calibri"
        hrun.font.size = Pt(8.5)
        hrun.font.color.rgb = RGBColor(100, 116, 139)
        
        # Footer with Page Number
        footer = section.footer
        fp = footer.paragraphs[0]
        fp.alignment = WD_ALIGN_PARAGRAPH.RIGHT
        frun1 = fp.add_run("CSE 400 Project Report | Page ")
        frun1.font.name = "Calibri"
        frun1.font.size = Pt(9)
        frun1.font.color.rgb = RGBColor(100, 116, 139)
        add_page_number(fp.add_run())

    # Title & Badge
    p_badge = doc.add_paragraph()
    r_badge = p_badge.add_run("CSE 400: SOFTWARE DEVELOPMENT PROJECT IV")
    r_badge.font.name = "Calibri"
    r_badge.font.size = Pt(9)
    r_badge.font.bold = True
    r_badge.font.color.rgb = RGBColor(37, 99, 235)
    
    p_title = doc.add_paragraph()
    r_title = p_title.add_run("Smart Buy Online (I-Buzz BD Management)")
    r_title.font.name = "Calibri"
    r_title.font.size = Pt(20)
    r_title.font.bold = True
    r_title.font.color.rgb = RGBColor(15, 23, 42)
    p_title.paragraph_format.space_after = Pt(2)
    
    p_sub = doc.add_paragraph()
    r_sub = p_sub.add_run("Complete Mathematical Models, Financial Algorithms & Business Calculation Specifications")
    r_sub.font.name = "Calibri"
    r_sub.font.size = Pt(11)
    r_sub.font.italic = True
    r_sub.font.color.rgb = RGBColor(71, 85, 105)
    p_sub.paragraph_format.space_after = Pt(14)
    
    # Metadata Table
    meta_table = doc.add_table(rows=1, cols=4)
    meta_table.alignment = WD_TABLE_ALIGNMENT.CENTER
    meta_table.autofit = False
    
    metas = [
        ("Platform Stack", "Flutter + Firestore"),
        ("Base Currency", "BDT (Taka ৳)"),
        ("Rounding Rule", "2-Decimal Currency"),
        ("Institution", "BUBT CSE Dept")
    ]
    
    hdr_cells = meta_table.rows[0].cells
    for i, (label, val) in enumerate(metas):
        hdr_cells[i].width = Inches(1.7)
        set_cell_background(hdr_cells[i], "F1F5F9")
        set_cell_margins(hdr_cells[i], 120, 120, 140, 140)
        p = hdr_cells[i].paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.LEFT
        r1 = p.add_run(f"{label}\n")
        r1.font.size = Pt(7.5)
        r1.font.bold = True
        r1.font.color.rgb = RGBColor(100, 116, 139)
        r2 = p.add_run(val)
        r2.font.size = Pt(9.5)
        r2.font.bold = True
        r2.font.color.rgb = RGBColor(15, 23, 42)

    doc.add_paragraph().paragraph_format.space_after = Pt(10)

    # Sections Helper
    def add_section_heading(text):
        h = doc.add_paragraph()
        h.paragraph_format.space_before = Pt(16)
        h.paragraph_format.space_after = Pt(6)
        h.paragraph_format.keep_with_next = True
        r = h.add_run(text)
        r.font.name = "Calibri"
        r.font.size = Pt(13)
        r.font.bold = True
        r.font.color.rgb = RGBColor(30, 58, 138)
        
    def add_formula_card(title, tag, formula, desc=None, dart_code=None):
        table = doc.add_table(rows=1, cols=1)
        table.alignment = WD_TABLE_ALIGNMENT.CENTER
        table.autofit = False
        cell = table.rows[0].cells[0]
        cell.width = Inches(6.9)
        set_cell_background(cell, "FAFAFA")
        set_cell_margins(cell, 140, 140, 180, 180)
        
        p = cell.paragraphs[0]
        p.paragraph_format.space_after = Pt(4)
        rt = p.add_run(title)
        rt.font.bold = True
        rt.font.size = Pt(10.5)
        rt.font.color.rgb = RGBColor(15, 23, 42)
        
        if tag:
            rt_tag = p.add_run(f"  [{tag}]")
            rt_tag.font.size = Pt(8.5)
            rt_tag.font.bold = True
            rt_tag.font.color.rgb = RGBColor(37, 99, 235)
            
        if desc:
            p_desc = cell.add_paragraph()
            p_desc.paragraph_format.space_after = Pt(6)
            rd = p_desc.add_run(desc)
            rd.font.size = Pt(9)
            rd.font.color.rgb = RGBColor(71, 85, 105)
            
        # Formula Box
        p_form = cell.add_paragraph()
        p_form.paragraph_format.space_after = Pt(4)
        p_form.paragraph_format.left_indent = Inches(0.1)
        rf = p_form.add_run(f"FORMULA:\n{formula}")
        rf.font.name = "Consolas"
        rf.font.size = Pt(9)
        rf.font.bold = True
        rf.font.color.rgb = RGBColor(15, 23, 42)
        
        if dart_code:
            p_code = cell.add_paragraph()
            p_code.paragraph_format.space_after = Pt(2)
            rc = p_code.add_run(f"Dart Implementation:\n{dart_code}")
            rc.font.name = "Consolas"
            rc.font.size = Pt(8)
            rc.font.color.rgb = RGBColor(3, 105, 161)
            
        doc.add_paragraph().paragraph_format.space_after = Pt(4)

    # 1. Mobile Inventory
    add_section_heading("1. Mobile Phone Inventory & Dynamic Landed Costing")
    add_formula_card(
        "1.1. Dynamic Landed Purchase Price (Mobile Sector)",
        "Stock Procurement",
        "Allocated Transport = Total Transport Overhead / Batch Unit Quantity\nNet Purchase Price = Base Purchase Rate + Allocated Transport",
        "Amortizes inward transport/courier fees equally across all mobile handsets received in a procurement batch.",
        "double calculateNetPurchasePrice({required double purchaseRate, required double transportCost}) => _roundCurrency(purchaseRate + transportCost);"
    )
    add_formula_card(
        "1.2. Realized Unit Profit on Mobile Sale",
        "Unit Margin",
        "Unit Profit = Selling Price - Net Purchase Price",
        "Computes realized profit per serialized IMEI phone unit sold.",
        "double calculateMobileProfit({required double sellingPrice, required double netPurchasePrice}) => _roundCurrency(sellingPrice - netPurchasePrice);"
    )

    # 2. Gadgets
    add_section_heading("2. Gadget & Accessory Multi-Cost Landed Margin Controller")
    add_formula_card(
        "2.1. Fully Burdened Gadget Landed Cost",
        "Multi-Cost Allocation",
        "Product Cost = Purchase Price + Transport + Packaging + Storage + Marketing + Damage Reserve + Other Costs",
        "Aggregates comprehensive operational overheads incurred during accessory import, packing, and warehousing."
    )
    add_formula_card(
        "2.2. Markup Selling Price from Target Margin %",
        "Pricing Strategy",
        "Selling Price = Product Cost × (1 + (Target Profit Margin % / 100))",
        "Determines required retail selling price to achieve specified margin percentage.",
        "double calculateSellingPrice({required double productCost, required double profitMargin}) => _roundCurrency(productCost + (productCost * (profitMargin / 100)));"
    )
    add_formula_card(
        "2.3. Weight-Based Transport Overhead Rate",
        "Logistics Weight Pricing",
        "Per-Gram Price = Per-Kg Logistics Rate / 1000\nUnit Transport Cost = Per-Gram Price × Product Weight (Grams)",
        "Used when logistics carriers charge by weight (e.g. BDT/KG)."
    )

    # 3. POS
    add_section_heading("3. Point-of-Sale (POS), Split-Payments & Invoice Settlement")
    add_formula_card(
        "3.1. POS Cart Totals & Net Payable Invoice",
        "Checkout Flow",
        "Item Subtotal = Unit Selling Price × Quantity\nInvoice Subtotal = ∑(Item Subtotals)\nGrand Total (Net Payable) = Invoice Subtotal - Flat Discount"
    )
    add_formula_card(
        "3.2. Multi-Payment Split, Customer Due ('Baki') & Change",
        "Split Settlement",
        "Total Paid = Cash Paid + Card Paid + MFS Paid\nIF Total Paid < Grand Total:\n    Customer Due (Baki) = Grand Total - Total Paid\n    Cashier Change = 0.00\nELSE:\n    Customer Due (Baki) = 0.00\n    Cashier Change = Total Paid - Grand Total",
        "Enables split settlements across multiple payment channels simultaneously."
    )
    add_formula_card(
        "3.3. Realized Gross Profit on POS Transaction",
        "Sales Profit",
        "Invoice Gross Profit = [ ∑(Item Selling Price - Item Net Purchase Cost) ] - Invoice Discount"
    )

    # 4. Returns
    add_section_heading("4. Sales Returns, Refund Adjustments & Inventory Write-Offs")
    add_formula_card(
        "4.1. Sales Return Refund & Debt Reconciliation",
        "Returns & Exchanges",
        "Gross Refund Value = Unit Sale Price × Returned Quantity\nDue Reduction Amount = MIN(Gross Refund Value, Customer Outstanding Due Balance)\nCash Refund Paid = Gross Refund Value - Due Reduction Amount",
        "Applies customer returns against their pending credit balance before disbursing physical cash."
    )
    add_formula_card(
        "4.2. Damaged Inventory Write-Off Valuation",
        "Shrinkage & Loss",
        "Total Damage Loss = ∑(Damaged Handsets × Net Purchase Cost) + ∑(Damaged Gadget Qty × Unit Cost)"
    )

    # 5. Customer Due
    add_section_heading("5. Customer Due ('Baki') Ledger Accounting")
    add_formula_card(
        "5.1. Customer Balance Update on Partial Collection",
        "Receivables Ledger",
        "Remaining Customer Due = Current Total Due - Installment Payment Received\nTotal Market Receivables = ∑(All Customer Outstanding Due Balances)"
    )

    # 6. Payroll
    add_section_heading("6. Employee Payroll, Salary Advances & Deductions")
    add_formula_card(
        "6.1. Net Monthly Payable Salary",
        "Payroll Processing",
        "Net Payable Salary = (Base Salary + Previous Due Paid + Advance Repaid + Bonus) - Deductions",
        "Reconciles employee base salaries with mid-month cash advances and overtime/bonuses.",
        "double get totalDeduction => (amount + duePaid + advance + bonus) - deductions;"
    )

    # 7. Capital
    add_section_heading("7. Capital, Investment & Total Business Valuation")
    add_formula_card(
        "7.1. Available Liquid Capital",
        "Cash Flow Balance",
        "Available Liquid Capital = Initial Capital + Capital Recovered - Capital Invested"
    )
    add_formula_card(
        "7.2. Total Enterprise Capital Valuation (Total Business Assets)",
        "Balance Sheet Equity",
        "Total Business Capital = Mobile Stock Value + Gadget Stock Value + Available Capital + Total Market Baki",
        "Real-time evaluation of total enterprise net worth.",
        "double get totalCapital => mobileStockValue + gadgetStockValue + availableCapital + totalBaki;"
    )

    # 8. Net Profit
    add_section_heading("8. Executive Financial Intelligence & Net Profit/Loss Engine")
    add_formula_card(
        "8.1. Consolidated True Net Profit Engine",
        "P&L Master Engine",
        "Realized Gross Profit = Total Sales Revenue - Cost of Goods Sold (COGS) - Discounts\nOperating Expenses = ∑(Shop Expenses: Rent, Utility, Tea, Transport, Misc) + ∑(Salaries Paid)\nTrue Net Operating Profit = Gross Profit - Gross Loss - Operating Expenses - Damaged Stock Loss",
        "Computes authentic net earnings by subtracting all direct product costs, operational overheads, staff salaries, and losses from total revenues.",
        "double get netProfit => totalProfit - totalLoss - totalSalaryPaid - totalOtherExpenses;"
    )
    add_formula_card(
        "8.2. Business Financial Health Ratios",
        "Performance KPIs",
        "Gross Profit Margin (%) = (Realized Gross Profit / Total Sales Revenue) × 100\nNet Profit Margin (%) = (True Net Operating Profit / Total Sales Revenue) × 100\nProfit Margin on Cost (%) = ((Selling Price - Net Landed Cost) / Net Landed Cost) × 100"
    )

    # Summary Table
    add_section_heading("★ Executive Calculation Summary Table")
    sum_table = doc.add_table(rows=1, cols=3)
    sum_table.alignment = WD_TABLE_ALIGNMENT.CENTER
    sum_table.autofit = False
    
    headers = ["Domain", "Metric Name", "Formula Definition"]
    widths = [Inches(1.8), Inches(2.2), Inches(2.9)]
    
    for i, h in enumerate(headers):
        cell = sum_table.rows[0].cells[i]
        cell.width = widths[i]
        set_cell_background(cell, "0F172A")
        p = cell.paragraphs[0]
        r = p.add_run(h)
        r.font.bold = True
        r.font.size = Pt(9)
        r.font.color.rgb = RGBColor(255, 255, 255)
        
    rows_data = [
        ("Mobile Inventory", "Dynamic Landed Cost", "Purchase Rate + (Transport Cost / Quantity)"),
        ("Gadget Inventory", "Target Selling Price", "Product Cost × (1 + Margin% / 100)"),
        ("POS Terminal", "Customer Due (Baki)", "Grand Total - (Cash + Card + MFS Paid)"),
        ("Customer Ledger", "Remaining Due", "Total Outstanding Due - Payment Collected"),
        ("Payroll", "Net Payable Salary", "Base Salary + Bonus - Advances - Deductions"),
        ("Capital / Assets", "Total Business Worth", "Stock Value + Available Cash + Total Baki"),
        ("P&L Master Engine", "True Net Profit", "Gross Margin - Expenses - Salaries - Losses"),
        ("BI KPI", "Net Margin (%)", "(True Net Profit / Total Revenue) × 100")
    ]
    
    for row_idx, (domain, metric, form) in enumerate(rows_data):
        row = sum_table.add_row()
        for i, val in enumerate([domain, metric, form]):
            c = row.cells[i]
            c.width = widths[i]
            if "P&L Master" in domain or "BI KPI" in domain:
                set_cell_background(c, "ECFDF5")
            else:
                set_cell_background(c, "FFFFFF" if row_idx % 2 == 0 else "F8FAFC")
            set_cell_margins(c, 80, 80, 100, 100)
            p = c.paragraphs[0]
            r = p.add_run(val)
            r.font.size = Pt(8.5)
            if i == 0:
                r.font.bold = True
                r.font.color.rgb = RGBColor(37, 99, 235)
            elif i == 1 and ("Net Profit" in val or "Worth" in val):
                r.font.bold = True
                r.font.color.rgb = RGBColor(5, 150, 105)

    doc.save(r"d:\I-buzz bd mangement\PROJECT_CALCULATIONS_SMART_BUY_ONLINE.docx")
    print("DOCX generated successfully!")

if __name__ == "__main__":
    build_docx()
