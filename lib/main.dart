import 'dart:io';
import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart';
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HyperGarageSale',
      theme: ThemeData(
        primarySwatch: Colors.lime
      ),
      home: new FirstScreen(),
    );
  }
}

class FirstScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('HyperGarageSale'),
      ),
      body: new Center(
        child: new MyListPage()
      ),
      floatingActionButton: new FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () {
            Navigator.push(
              context,
              new MaterialPageRoute(builder: (context) => new AddPage(title: 'HyperGarageSale'))
            );
          },
        ),
    );
  }
}

class MyListPage extends StatefulWidget {
 @override
 _MyListState createState() {
   return _MyListState();
 }
}

class _MyListState extends State<MyListPage> {
 @override
 Widget build(BuildContext context) {
   return Scaffold(
     body: _buildBody(context),
   );
 }

 Widget _buildBody(BuildContext context) {
   return StreamBuilder<QuerySnapshot>(
     stream: Firestore.instance.collection('sale').snapshots(),
     builder: (context, snapshot) {
       if (!snapshot.hasData) return LinearProgressIndicator();
       return _buildList(context, snapshot.data.documents);
     },
   );
 }

 Widget _buildList(BuildContext context, List<DocumentSnapshot> snapshot) {
   return ListView(
     padding: const EdgeInsets.only(top: 30.0),
     children: snapshot.map((data) => _buildListItem(context, data)).toList(),
   );
 }

 Widget _buildListItem(BuildContext context, DocumentSnapshot data) {
   final record = Record.fromSnapshot(data);

   return Padding(
     key: ValueKey(record.name),
     padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
     child: Container(
       decoration: BoxDecoration(
         border: Border.all(color: Colors.lime),
         borderRadius: BorderRadius.circular(5.0),
       ),
       child: ListTile(  
         leading:SizedBox(
           height: 100.0,
           width: 100.0,
           child: new Image.network(record.pictures[0]),
         ),
         title: Text(record.name),
         trailing: Text('\$' + record.price.toString()),
         onTap: () => {
           Navigator.push(
              context,
              new MaterialPageRoute(builder: (context) => new DetailPage
              (title: 'HyperGarageSale', record: record))
            )
         }
       ),
     ),
   );
 }
}

class DetailPage extends StatefulWidget {
  DetailPage({Key key, this.title, this.record}) : super(key: key);
  final String title;
  final Record record;

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: 
        new ListView(
          children: <Widget>[
            new Container(
              padding: EdgeInsets.all(20.0),
              child: Center(
              child: Column(
                children: <Widget>[
                  //Image.network(widget.record.pictures[0]),
                  new BannerGalleryWidget(record: widget.record),
                  Text(""),
                  Text(widget.record.name + " :                      \$ " +widget.record.price.toString(),
                    style: new TextStyle(
                      fontSize: 27.0,
                    ),
                  ),
                  Text(""),
                  Text(""),
                  Text(widget.record.desc,
                    textAlign: TextAlign.justify,
                    style: new TextStyle(
                      fontSize: 20.0
                    ),
                  )
                ],
              )
            ),
            ),
          ],
        )
    );
  }
}

class BannerGalleryWidget extends StatefulWidget {
  BannerGalleryWidget({Key key, this.record}) : super(key: key);
  final Record record;
  @override
  State<StatefulWidget> createState() {
    return BannerGalleryWidgetState();
  }
}

class BannerGalleryWidgetState extends State<BannerGalleryWidget> {
  final PageController controller = PageController();
  void _pageChanged(int index) {
    setState(() {});
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SizedBox(
          height: 300.0,
          child: Container(
            child: PageView.builder(
              onPageChanged: _pageChanged,
              controller: controller,
              itemBuilder: (context, index) {
                return new Center(
                  child: Image.network(widget.record.pictures[index]),
                );
              },
              itemCount: widget.record.pictures.length,
            ),
          )
        ),
         Indicator(
          controller: controller,
          itemCount: widget.record.pictures.length,
        ),
      ],
    );
    
  }
}

class Record {
 String name;
 int price;
 String desc;
 List<dynamic> pictures;
 DocumentReference reference;

 Record.fromMap(Map<String, dynamic> map, {this.reference})
     : 
       assert(map['pictures'].length != 0),
       name = map['name'],
       price = map['price'],
       desc = map['desc'],
       pictures = map['pictures'];
 Record.fromSnapshot(DocumentSnapshot snapshot)
     : this.fromMap(snapshot.data, reference: snapshot.reference);
}

class AddPage extends StatefulWidget {
  AddPage({Key key, this.title, this.record}) : super(key: key);
  final String title;
  final Record record;

  @override
  _AddPageState createState() => _AddPageState();
}
List<String> urlList = new List();
class _AddPageState extends State<AddPage> {
  TextEditingController _nameController = new TextEditingController();
  TextEditingController _priceController = new TextEditingController();
  TextEditingController _descController = new TextEditingController();
  TextEditingController _picsController = new TextEditingController();
  
  File _imageFile;  
  String filename;
  Future _onImageButtonPressed()async {
    var selectedImage = await ImagePicker.pickImage(source: ImageSource.gallery);
    setState(() {
      _imageFile = selectedImage;
      if(_imageFile != null){
        filename = basename(_imageFile.path);
      }
    });
  }
  
  Widget uploadArea(){
    return Column(
      children: <Widget>[
        Image.file(_imageFile, width: 200),
        RaisedButton(
          color: Colors.lime,
          shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(30.0)),
          child: Text("Upload", style: new TextStyle(color: Colors.white),),
          onPressed: uploadImage,
        )
      ],
    );
  }

  Future<String> uploadImage() async{
    StorageReference ref = FirebaseStorage.instance.ref().child(filename);
    StorageUploadTask uploadTask = ref.putFile(_imageFile);
    
    var downUrl = await(await uploadTask.onComplete).ref.getDownloadURL();
    var url = downUrl.toString();
    print(url);
    urlList.add(url);
    return url;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView(
        padding: EdgeInsets.all(20.0),
        children: <Widget>[
          TextField(
            decoration: InputDecoration(
                labelText: "Title",
                hintText: "Enter title of the item",
                //prefixIcon: Icon(Icons.title)
            ),
            controller: _nameController,
          ),
          
          TextField(
            decoration: InputDecoration(
                labelText: "Price",
                hintText: "Enter Price",
                //prefixIcon: Icon(Icons.attach_money)
            ),
            controller: _priceController,
          ),

          TextField(
            decoration: InputDecoration(
              labelText: "Description",
              hintText: "Enter Description of the item",
              //prefixIcon: Icon(Icons.text_fields)
            ),
            maxLines: 10,
            controller: _descController,
          ),
          
          _imageFile == null?
          Center(
            child: Text("select an image", style: new TextStyle(color: Colors.white),)
          ):uploadArea(),
          

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(1.0)
                ),
                flex: 2,
              ),
              RaisedButton(
                color: Colors.lime,
                shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(30.0)),
                child: 
                Text("IMAGE", style: new TextStyle(color: Colors.white)),
                  onPressed: () =>{
                    _onImageButtonPressed()
                  },
              ),
              
              
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(1.0)
                ),
                flex: 10,
              ),
              
              new MyButton(
                nController:_nameController, 
                pController:_priceController,
                dController:_descController,
              ),
              
                
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(1.0)
                ),
                flex: 2,
              ),
            ], 
          )
        ],
        ), 
    );
  }
}

class MyButton extends StatelessWidget {
MyButton( {
  Key key,
  this.nController, this.pController, this.dController
}) : super(key: key);
final TextEditingController nController;
final TextEditingController pController;
final TextEditingController dController;

  @override
  Widget build(BuildContext context) {
    return new RaisedButton(
      child: new Text("POST",
        style: new TextStyle(color: Colors.white)
      ),
      color: Colors.lime,
      shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(30.0)),
      onPressed: () {
        Map<String,dynamic> map = new Map();
                map['name'] = nController.text;
                map['price'] = int.parse(pController.text);
                map['desc'] = dController.text;
                map['pictures'] = urlList;
                Firestore.instance.collection('sale').add(map);

        Scaffold.of(context).showSnackBar(new SnackBar(
          content: new Text("You have posted an item"),
          duration: new Duration(seconds: 2),
          backgroundColor: Colors.lime,
          action: new SnackBarAction(
            label: "Close",
            textColor: Colors.white,
            onPressed: () {
            },
          ),
        ));
      },
    );
  }
}


class Indicator extends StatelessWidget {
  Indicator({
    this.controller,
    this.itemCount: 0,
  }) : assert(controller != null);

  final PageController controller;

  final int itemCount;

  final Color normalColor = Colors.indigo;

  final Color selectedColor = Colors.blue;

  final double size = 8.0;

  final double spacing = 4.0;

  Widget _buildIndicator(
      int index, int pageCount, double dotSize, double spacing) {
    bool isCurrentPageSelected = index ==
        (controller.page != null ? controller.page.round() % pageCount : 0);

    return new Container(
      height: size,
      width: size + (2 * spacing),
      child: new Center(
        child: new Material(
          color: isCurrentPageSelected ? selectedColor : normalColor,
          type: MaterialType.circle,
          child: new Container(
            width: dotSize,
            height: dotSize,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: new List<Widget>.generate(itemCount, (int index) {
        return _buildIndicator(index, itemCount, size, spacing);
      }),
    );
  }
}