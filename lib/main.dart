import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';


void main() {
  runApp(MaterialApp(
    home: Home(),
  )
      );

}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  List _toDoList = [];

  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos;

  @override
  void initState() {
    super.initState();
      _readData().then((data) {

        setState(() {
          _toDoList = json.decode(data);
        });

      });
  }

  final _toDoController = TextEditingController();
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _addToDo(){

    setState(() {
      Map<String, dynamic> newToDo = Map();
      newToDo["title"] = _toDoController.text;
      _toDoController.text = "";
      newToDo["ok"] = false;
      _toDoList.add(newToDo);
      _saveData();
    });
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
        _toDoList.sort( (check , noCheck){
        if(check["ok"] && !noCheck["ok"]) return 1;
        else if(!check["ok"] && noCheck["ok"]) return -1;
        else return 0;
      });
      _saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Tarefas"),
        backgroundColor: Colors.deepPurpleAccent,
        centerTitle: true
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 2.0, 7.0, 4.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Form(
                    key: _formKey,
                      child: TextFormField(
                        controller: _toDoController,
                        textInputAction: TextInputAction.done,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                            labelText: "Nova tarefa",
                            labelStyle: TextStyle(color: Colors.deepPurpleAccent,
                                fontSize: 20.0)
                        ),
                        validator: (value){
                            if(value.isEmpty){
                              return "Obrigatório";
                            }
                          },
                        onFieldSubmitted: (term){
                          if(_formKey.currentState.validate()){
                            _addToDo();
                          }
                          }
                      ),
                  ),
                ),   
                IconButton(
                    icon: Icon(Icons.add_circle),
                    color: Colors.deepPurpleAccent,
                    iconSize: 50.0,
                    onPressed: (){
                      if(_formKey.currentState.validate()){
                        _addToDo();
                      }
                    },
                ),
              ],
            ),
          ),
          Expanded(
              child: RefreshIndicator(
                  child: ListView.builder(
                    padding: EdgeInsets.only(top: 10.0),
                    itemCount: _toDoList.length,
                    itemBuilder: buildItem,
                  ),
                  onRefresh: _refresh,
              )
          ),
        ],
      ),
    );
  }

  Widget buildItem(context, index){
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.99 , 0.0),
          child: Icon(Icons.delete, color: Colors.white),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        //onChanged: (){} ,
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]["ok"] ?
          Icons.check_circle_outline : Icons.error_outline),
        ),
        onChanged: (c){
          setState(() {
            _toDoList[index]["ok"] = c;
            _saveData();
          });
        }
      ),
      onDismissed: (direction) {

        setState(() {
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedPos = index;
          _toDoList.removeAt(index);
          _saveData();

          final snack = SnackBar(
            content: Text("Tarefa \" ${_lastRemoved["title"]}\" removida!"),
            action: SnackBarAction(label: "Desfazer",
            onPressed: () {
              setState(() {
              _toDoList.insert(_lastRemovedPos, _lastRemoved);
              _saveData();
              });
              }
            ),
            duration: Duration(seconds: 3),
          );

          Scaffold.of(context).showSnackBar(snack);

        });

    },
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile(); // awwait esperar algo/resposta acontecer
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    }catch (e) {
      return null;
    }
  }

}

