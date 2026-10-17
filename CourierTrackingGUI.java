import javax.swing.*; import javax.swing.plaf.basic.BasicButtonUI;
import javax.swing.table.*; import java.awt.*; import java.sql.*; import java.util.*;
import javax.swing.border.EmptyBorder;

public class CourierTrackingGUI extends JFrame {
    static final Color NAVY=new Color(15,23,42),BLUE=new Color(37,99,235),GREEN=new Color(5,150,105),
        BG=new Color(248,250,252),BORDER=new Color(226,232,240),SUBHDR=new Color(241,245,249),TX=new Color(51,65,85);
    Connection con; JLabel statusLbl=new JLabel("  Not connected");
    JTextField usrF=tf("root",10),urlF=tf("jdbc:mysql://localhost:3306/courier_tracking?serverTimezone=UTC",0);
    JPasswordField pwdF=new JPasswordField(10);
    JComboBox<String> cCmb=cmb(),pCmb=cmb(),hCmb=cmb(),iCmb=cmb(),
        pmCmb=cmb("All","EasyPaisa","JazzCash","Bank Transfer","Cash","Credit Card","Debit Card");
    JTable cT=tbl(),aT=tbl(),ptT=tbl(),hT=tbl(),iT=tbl(),pyT=tbl(),wT=tbl(),ocT=tbl(),rT=tbl(),csT=tbl(),qT=tbl();
    JCheckBox ckU=ck("Unpaid",true),ckPp=ck("Partially Paid",true),ckO=ck("Overdue",true),ckPd=ck("Paid",false);
    JTextArea sqlA=new JTextArea(4,60); JComboBox<String[]> qCmb;

    @SuppressWarnings("unchecked")
    public CourierTrackingGUI() {
        setTitle("Courier & Package Tracking System");
        setSize(1280,820); setDefaultCloseOperation(EXIT_ON_CLOSE); setLocationRelativeTo(null);

        // Header: just title + connect button
        JPanel hdr=new JPanel(new BorderLayout()); hdr.setBackground(NAVY); hdr.setBorder(new EmptyBorder(20,28,20,28));
        JLabel title=new JLabel("  Courier & Package Tracking System");
        title.setFont(new Font("Segoe UI",Font.BOLD,24)); title.setForeground(Color.WHITE);
        JButton connBtn=btn("Connect to Database",BLUE); connBtn.addActionListener(e->showConnectDialog());
        hdr.add(title,BorderLayout.WEST); hdr.add(connBtn,BorderLayout.EAST);

        // Queries tab
        sqlA.setFont(new Font(Font.MONOSPACED,Font.PLAIN,12)); sqlA.setBackground(BG);
        qCmb=new JComboBox<>(buildQueries()); qCmb.setPreferredSize(new Dimension(340,32));
        qCmb.setRenderer((l,v,i,s,f)->new JLabel(v==null?"":v[0]));
        qCmb.addActionListener(e->{String[] q=(String[])qCmb.getSelectedItem();if(q!=null)sqlA.setText(q[1]);});
        JButton runQ=btn("Run Query",GREEN);
        runQ.addActionListener(e->{String[] q=(String[])qCmb.getSelectedItem();if(q!=null&&con!=null)sql(qT,q[1]);});
        if(qCmb.getItemCount()>0) sqlA.setText(qCmb.getItemAt(0)[1]);

        // Action buttons
        JButton lcB=btn("Load",BLUE),tpB=btn("Track",BLUE),lhB=btn("Load",BLUE),
                liB=btn("Load",BLUE),lpB=btn("Load",BLUE),lwB=btn("Load Workload",BLUE),rcB=btn("Refresh",GREEN);
        lcB.addActionListener(e->loadCust()); tpB.addActionListener(e->loadTrack()); lhB.addActionListener(e->loadHub());
        liB.addActionListener(e->loadInv()); lpB.addActionListener(e->loadPay()); rcB.addActionListener(e->loadComplaints());
        lwB.addActionListener(e->sql(wT,"SELECT da.AgentID,da.FullName,da.BaseHubID,COUNT(DISTINCT va.ShipmentID) Active FROM DeliveryAgent da LEFT JOIN VehicleAssignment va ON va.AgentID=da.AgentID AND va.AssignmentStatus IN('Assigned','Dispatched','In Transit','Out for Delivery') GROUP BY da.AgentID,da.FullName,da.BaseHubID ORDER BY Active DESC"));

        // Tabs
        JTabbedPane tabs=new JTabbedPane(); tabs.setFont(new Font("Segoe UI",Font.BOLD,14));
        tabs.addTab("Parcel Tracker", scroll(
            sec("Customer Parcels",row(lbl("Customer:"),cCmb,lcB),cT),
            sec("Addresses",null,aT),
            sec("Tracking Log",row(lbl("Parcel ID:"),pCmb,tpB),ptT),
            sec("Hub Activity",row(lbl("Hub:"),hCmb,lhB),hT)));
        tabs.addTab("Finance", scroll(
            sec("Invoices",row(lbl("Customer:"),iCmb,ckU,ckPp,ckO,ckPd,liB),iT),
            sec("Payments",row(lbl("Method:"),pmCmb,lpB),pyT),
            sec("Agent Workload",row(lwB),wT)));
        tabs.addTab("Complaints", scroll(
            sec("Open Complaints",row(rcB),ocT),
            sec("Resolution Details",null,rT),
            sec("Complaint Statistics",null,csT)));
        tabs.addTab("SQL Queries", scroll(
            sec("Select & Run Query",row(lbl("Query:"),qCmb,runQ),new JScrollPane(sqlA)),
            sec("Results",null,qT)));

        // Footer status bar
        JPanel foot=new JPanel(new FlowLayout(FlowLayout.LEFT,16,6));
        foot.setBackground(SUBHDR); foot.setBorder(BorderFactory.createMatteBorder(1,0,0,0,BORDER));
        statusLbl.setFont(new Font("Segoe UI",Font.PLAIN,13)); statusLbl.setForeground(new Color(100,116,139));
        foot.add(statusLbl);

        add(hdr,BorderLayout.NORTH); add(tabs,BorderLayout.CENTER); add(foot,BorderLayout.SOUTH);
        SwingUtilities.invokeLater(this::showConnectDialog);
    }

    void showConnectDialog() {
        JPanel p=new JPanel(new GridLayout(3,2,10,10)); p.setBorder(new EmptyBorder(12,12,12,12));
        p.add(new JLabel("URL:")); p.add(urlF);
        p.add(new JLabel("Username:")); p.add(usrF);
        p.add(new JLabel("Password:")); p.add(pwdF);
        int r=JOptionPane.showConfirmDialog(this,p,"Connect to Database",JOptionPane.OK_CANCEL_OPTION,JOptionPane.PLAIN_MESSAGE);
        if(r==JOptionPane.OK_OPTION) connect();
    }

    void connect() {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            if(con!=null&&!con.isClosed()) con.close();
            con=DriverManager.getConnection(urlF.getText().trim(),usrF.getText().trim(),new String(pwdF.getPassword()));
            statusLbl.setText("  Connected successfully"); statusLbl.setForeground(GREEN); reload();
        } catch(Exception ex){
            statusLbl.setText("  Error: "+ex.getMessage()); statusLbl.setForeground(new Color(220,38,38));
            JOptionPane.showMessageDialog(this,ex.getMessage(),"Connection Error",JOptionPane.ERROR_MESSAGE);
        }
    }

    void reload() {
        fill(cCmb,"SELECT CustomerID,Name FROM Customer ORDER BY CustomerID");
        fill(pCmb,"SELECT ParcelID FROM Parcel ORDER BY ParcelID");
        fill(hCmb,"SELECT HubID,HubName,City FROM Hub ORDER BY HubID");
        java.util.List<String> ic=new ArrayList<>(); ic.add("All");
        ic.addAll(list("SELECT CustomerID,Name FROM Customer ORDER BY CustomerID"));
        iCmb.setModel(new DefaultComboBoxModel<>(ic.toArray(new String[0])));
        loadCust(); loadComplaints();
    }

    void loadCust(){ if(con==null)return; String s=(String)cCmb.getSelectedItem(); if(s==null)return;
        sql(cT,"SELECT p.ParcelID,p.ParcelType,p.Weight,p.Status,s.ShipmentID,s.EstimatedDelivery FROM Parcel p LEFT JOIN Shipment s ON p.ParcelID=s.ParcelID WHERE p.CustomerID=?",id(s));
        sql(aT,"SELECT AddressID,Street,City,Province,PostalCode FROM Address WHERE CustomerID=? ORDER BY AddressID",id(s)); }
    void loadTrack(){ if(con==null)return; String s=(String)pCmb.getSelectedItem(); if(s==null)return;
        sql(ptT,"SELECT t.LogID,t.Status,t.UpdatedAt,h.HubName,h.City FROM TrackingLog t LEFT JOIN Hub h ON t.HubID=h.HubID WHERE t.ParcelID=? ORDER BY t.UpdatedAt DESC",id(s)); }
    void loadHub(){ if(con==null)return; String s=(String)hCmb.getSelectedItem(); if(s==null)return;
        sql(hT,"SELECT ParcelID,Status,UpdatedAt,AssignmentID FROM TrackingLog WHERE HubID=? ORDER BY UpdatedAt DESC",id(s)); }
    void loadInv() {
        if(con==null)return; java.util.List<String> st=new ArrayList<>();
        if(ckU.isSelected())st.add("Unpaid"); if(ckPp.isSelected())st.add("Partially Paid");
        if(ckO.isSelected())st.add("Overdue"); if(ckPd.isSelected())st.add("Paid");
        if(st.isEmpty()){JOptionPane.showMessageDialog(this,"Select at least one status.");return;}
        String sel=(String)iCmb.getSelectedItem(); java.util.List<Object> p=new ArrayList<>();
        StringBuilder q=new StringBuilder("SELECT i.InvoiceID,c.Name,i.TotalAmount,i.InvoiceDate,i.DueDate,i.InvoiceStatus FROM Invoice i JOIN Customer c ON i.CustomerID=c.CustomerID WHERE ");
        if(sel!=null&&!sel.equals("All")){q.append("i.CustomerID=? AND ");p.add(id(sel));}
        q.append("i.InvoiceStatus IN("); for(int i=0;i<st.size();i++){if(i>0)q.append(",");q.append("?");p.add(st.get(i));} q.append(") ORDER BY i.DueDate");
        sql(iT,q.toString(),p.toArray());
    }
    void loadPay(){ if(con==null)return; String m=(String)pmCmb.getSelectedItem();
        String b="SELECT p.PaymentID,c.Name,p.AmountPaid,p.PaymentMethod,p.PaymentDate,p.PaymentStatus FROM Payment p JOIN Invoice i ON p.InvoiceID=i.InvoiceID JOIN Customer c ON i.CustomerID=c.CustomerID";
        if("All".equals(m)) sql(pyT,b+" ORDER BY p.PaymentDate DESC"); else sql(pyT,b+" WHERE p.PaymentMethod=? ORDER BY p.PaymentDate DESC",m); }
    void loadComplaints(){ if(con==null)return;
        sql(ocT,"SELECT c.ComplaintID,cu.Name,c.ParcelID,c.ComplaintType,c.Status,c.CreatedAt FROM Complaint c JOIN Customer cu ON c.CustomerID=cu.CustomerID WHERE c.Status='Open' ORDER BY c.CreatedAt");
        sql(rT,"SELECT c.ComplaintID,cu.Name,c.ComplaintType,cr.ResolutionType,cr.ResolvedAt,da.FullName Agent FROM Complaint c JOIN Customer cu ON c.CustomerID=cu.CustomerID LEFT JOIN ComplaintResolution cr ON c.ComplaintID=cr.ComplaintID LEFT JOIN DeliveryAgent da ON cr.AgentID=da.AgentID ORDER BY c.ComplaintID");
        sql(csT,"SELECT ComplaintType,COUNT(*) Total FROM Complaint GROUP BY ComplaintType ORDER BY Total DESC"); }

    void sql(JTable tbl,String query,Object...ps){
        try(PreparedStatement s=con.prepareStatement(query)){
            for(int i=0;i<ps.length;i++) s.setObject(i+1,ps[i]);
            ResultSet rs=s.executeQuery(); ResultSetMetaData m=rs.getMetaData(); int nc=m.getColumnCount();
            Vector<String> cols=new Vector<>(); for(int i=1;i<=nc;i++) cols.add(m.getColumnLabel(i));
            Vector<Vector<Object>> rows=new Vector<>();
            while(rs.next()){Vector<Object> r=new Vector<>();for(int i=1;i<=nc;i++)r.add(rs.getObject(i));rows.add(r);}
            tbl.setModel(new DefaultTableModel(rows,cols){public boolean isCellEditable(int r,int c){return false;}});
        }catch(SQLException ex){statusLbl.setText("  Error: "+ex.getMessage()); statusLbl.setForeground(new Color(220,38,38));}
    }
    void fill(JComboBox<String> cb,String q){cb.setModel(new DefaultComboBoxModel<>(list(q).toArray(new String[0])));}
    java.util.List<String> list(String q){
        java.util.List<String> r=new ArrayList<>();
        try(Statement s=con.createStatement();ResultSet rs=s.executeQuery(q)){
            while(rs.next()){int n=rs.getMetaData().getColumnCount(); String v=rs.getString(1);
                for(int i=2;i<=n;i++) v+=" - "+rs.getString(i); r.add(v);}
        }catch(Exception e){statusLbl.setText("  "+e.getMessage());} return r;
    }
    String id(String s){int i=s.indexOf(" - ");return i>=0?s.substring(0,i).trim():s.trim();}

    static JTextField tf(String t,int c){JTextField f=new JTextField(t,c==0?40:c);f.setFont(new Font("Segoe UI",Font.PLAIN,13));return f;}
    static JComboBox<String> cmb(String...v){JComboBox<String> c=new JComboBox<>(v);c.setFont(new Font("Segoe UI",Font.PLAIN,13));c.setPreferredSize(new Dimension(220,32));return c;}
    static JTable tbl(){
        JTable t=new JTable(new DefaultTableModel());
        t.setFont(new Font("Segoe UI",Font.PLAIN,13)); t.setRowHeight(28);
        t.getTableHeader().setFont(new Font("Segoe UI",Font.BOLD,13));
        t.getTableHeader().setBackground(new Color(241,245,249));
        t.getTableHeader().setForeground(new Color(30,41,59));
        t.setGridColor(new Color(226,232,240)); t.setShowGrid(true); t.setFillsViewportHeight(true);
        t.setAutoResizeMode(JTable.AUTO_RESIZE_ALL_COLUMNS);
        t.setPreferredScrollableViewportSize(new Dimension(400,200));
        t.setDefaultRenderer(Object.class,(tb,v,s,f,r,c)->{
            JLabel l=new JLabel(v==null?"":v.toString()); l.setOpaque(true);
            l.setFont(new Font("Segoe UI",Font.PLAIN,13)); l.setBorder(new EmptyBorder(0,8,0,8));
            l.setBackground(s?new Color(219,234,254):r%2==0?Color.WHITE:new Color(248,250,252));
            l.setForeground(s?new Color(30,64,175):new Color(51,65,85)); return l;
        }); return t;
    }
    static JButton btn(String t,Color bg){JButton b=new JButton(t);b.setUI(new BasicButtonUI());b.setBackground(bg);b.setForeground(Color.WHITE);b.setFont(new Font("Segoe UI",Font.BOLD,13));b.setOpaque(true);b.setFocusPainted(false);b.setBorder(new EmptyBorder(8,16,8,16));b.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));return b;}
    static JLabel lbl(String t){JLabel l=new JLabel(t);l.setFont(new Font("Segoe UI",Font.PLAIN,13));l.setForeground(TX);return l;}
    static JCheckBox ck(String t,boolean s){JCheckBox c=new JCheckBox(t,s);c.setFont(new Font("Segoe UI",Font.PLAIN,13));c.setOpaque(false);return c;}
    static JPanel row(Component...cs){JPanel p=new JPanel(new FlowLayout(FlowLayout.LEFT,10,8));p.setBackground(SUBHDR);p.setBorder(BorderFactory.createMatteBorder(0,0,1,0,BORDER));for(Component c:cs)p.add(c);return p;}
    static JScrollPane scroll(Component...cs){
        JPanel p=new JPanel(); p.setLayout(new BoxLayout(p,BoxLayout.Y_AXIS)); p.setBackground(BG); p.setBorder(new EmptyBorder(8,8,8,8));
        for(Component c:cs){p.add(c);p.add(Box.createVerticalStrut(8));}
        JScrollPane sp=new JScrollPane(p,JScrollPane.VERTICAL_SCROLLBAR_AS_NEEDED,JScrollPane.HORIZONTAL_SCROLLBAR_NEVER);
        sp.setBorder(null); sp.getVerticalScrollBar().setUnitIncrement(20); sp.getVerticalScrollBar().setPreferredSize(new Dimension(8,0)); return sp;
    }
    static JPanel sec(String title,Component toolbar,Component content){
        JPanel p=new JPanel(new BorderLayout()); p.setBackground(Color.WHITE);
        p.setBorder(BorderFactory.createLineBorder(BORDER));
        JPanel hd=new JPanel(new BorderLayout()); hd.setBackground(SUBHDR);
        hd.setBorder(BorderFactory.createMatteBorder(0,0,1,0,BORDER));
        JLabel tl=new JLabel("  "+title); tl.setFont(new Font("Segoe UI",Font.BOLD,13)); tl.setForeground(new Color(30,41,59)); tl.setBorder(new EmptyBorder(8,4,4,4));
        hd.add(tl,BorderLayout.NORTH); if(toolbar!=null) hd.add(toolbar,BorderLayout.SOUTH);
        p.add(hd,BorderLayout.NORTH);
        if(content!=null){ JScrollPane sp=content instanceof JScrollPane?(JScrollPane)content:content instanceof JTable?new JScrollPane((JTable)content):null;
            if(sp!=null){sp.setBorder(null);p.add(sp,BorderLayout.CENTER);}else p.add(content,BorderLayout.CENTER);}
        return p;
    }

    String[][] buildQueries(){return new String[][]{
        {"a. Parcels for Customer C001","SELECT * FROM Parcel WHERE CustomerID='C001'"},
        {"b. Customers with Addresses","SELECT c.Name,c.Email,a.Street,a.City,a.Province FROM Customer c JOIN Address a ON c.CustomerID=a.CustomerID"},
        {"c. Shipments Origin to Destination","SELECT s.ShipmentID,s.EstimatedDelivery,o.City Origin,d.City Destination FROM Shipment s JOIN Address o ON s.OriginAddressID=o.AddressID JOIN Address d ON s.DestinationAddressID=d.AddressID"},
        {"d. Current Status of Parcel P001","SELECT * FROM TrackingLog WHERE ParcelID='P001' ORDER BY UpdatedAt DESC LIMIT 1"},
        {"e. Parcels at Hub H001","SELECT * FROM TrackingLog WHERE HubID='H001'"},
        {"f. Tracking with Hub Name","SELECT t.ParcelID,t.Status,t.UpdatedAt,h.HubName FROM TrackingLog t JOIN Hub h ON t.HubID=h.HubID"},
        {"g. Outstanding Invoices C005","SELECT i.InvoiceID,c.Name,i.TotalAmount,i.DueDate,i.InvoiceStatus FROM Invoice i JOIN Customer c ON i.CustomerID=c.CustomerID WHERE i.CustomerID='C005' AND i.InvoiceStatus IN('Unpaid','Partially Paid','Overdue')"},
        {"h. Agent Workload","SELECT da.AgentID,da.FullName,da.BaseHubID,COUNT(DISTINCT va.ShipmentID) Active FROM DeliveryAgent da LEFT JOIN VehicleAssignment va ON va.AgentID=da.AgentID AND va.AssignmentStatus IN('Assigned','Dispatched','In Transit','Out for Delivery') GROUP BY da.AgentID,da.FullName,da.BaseHubID ORDER BY Active DESC"},
        {"i. EasyPaisa Payments","SELECT p.PaymentID,c.Name,p.AmountPaid,p.PaymentDate,p.PaymentStatus FROM Payment p JOIN Invoice i ON p.InvoiceID=i.InvoiceID JOIN Customer c ON i.CustomerID=c.CustomerID WHERE p.PaymentMethod='EasyPaisa' ORDER BY p.PaymentDate DESC"},
        {"j. Open Complaints","SELECT c.ComplaintID,cu.Name,c.ParcelID,c.ComplaintType,c.Description,c.CreatedAt FROM Complaint c JOIN Customer cu ON c.CustomerID=cu.CustomerID WHERE c.Status='Open' ORDER BY c.CreatedAt"},
        {"k. Complaints with Resolution","SELECT c.ComplaintID,cu.Name,c.ComplaintType,c.Status,cr.ResolutionType,cr.ResolvedAt,da.FullName Agent FROM Complaint c JOIN Customer cu ON c.CustomerID=cu.CustomerID LEFT JOIN ComplaintResolution cr ON c.ComplaintID=cr.ComplaintID LEFT JOIN DeliveryAgent da ON cr.AgentID=da.AgentID ORDER BY c.ComplaintID"},
        {"l. Complaints by Type","SELECT ComplaintType,COUNT(*) Total FROM Complaint GROUP BY ComplaintType ORDER BY Total DESC"}
    };}

    public static void main(String[] a){
        try{UIManager.setLookAndFeel("javax.swing.plaf.metal.MetalLookAndFeel");}catch(Exception e){}
        SwingUtilities.invokeLater(()->new CourierTrackingGUI().setVisible(true));
    }
}
