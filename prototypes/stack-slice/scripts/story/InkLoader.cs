using Godot;
using GodotInk;

namespace StackSlice;

// Единственный свой C# в игре. Нужен по двум причинам:
// 1) GDScript не умеет вызывать статические методы C#-классов;
// 2) InkStory.Create(json) в GodotInk (master 49e35b5) пишет JSON в поле, минуя свойство RawStory,
//    и рантайм Ink не создаётся (NullReferenceException на первом же вызове). Наследник ставит
//    свойство, как это делает импорт .ink в редакторе.
[GlobalClass]
public partial class InkLoader : RefCounted
{
    public InkStory Load(string json) => new JsonInkStory(json);
}

public partial class JsonInkStory : InkStory
{
    public JsonInkStory() { }

    public JsonInkStory(string json)
    {
        RawStory = json;
    }
}
