using System.Reflection;
using Godot;
using GodotInk;

namespace TmaGame;

// Единственный свой C# в игре. Нужен по трём причинам:
// 1) GDScript не умеет вызывать статические методы C#-классов;
// 2) InkStory.Create(json) в GodotInk (master 49e35b5) пишет JSON в поле, минуя свойство RawStory,
//    и рантайм Ink не создаётся (NullReferenceException на первом же вызове). Наследник ставит
//    свойство, как это делает импорт .ink в редакторе;
// 3) у ChoosePathString в GodotInk несколько перегрузок, а GDScript видит только одну из них;
// 4) GodotInk не отдаёт текущий путь в истории, а по нему игра узнаёт, что началась новая сцена
//    (счётчики посещений Ink ведёт не для всех узлов);
// 5) GodotInk не отдаёт теги вариантов выбора, а по тегу #obj: вариант становится объектом на карте.
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

    private static readonly FieldInfo RuntimeField =
        typeof(InkStory).GetField("runtimeStory", BindingFlags.NonPublic | BindingFlags.Instance)!;

    // Перейти к узлу Ink с аргументами (узлы осмотра, проверка ухода с карты охоты).
    public void GoTo(string path, Godot.Collections.Array args)
    {
        var list = new Variant[args.Count];
        for (int i = 0; i < args.Count; i++)
            list[i] = args[i];
        ChoosePathString(path, true, list);
    }

    // Теги текущих вариантов выбора, по одному массиву на вариант.
    public Godot.Collections.Array<string[]> ChoiceTags()
    {
        var story = (Ink.Runtime.Story)RuntimeField.GetValue(this)!;
        var outList = new Godot.Collections.Array<string[]>();
        foreach (var choice in story.currentChoices)
            outList.Add(choice.tags?.ToArray() ?? System.Array.Empty<string>());
        return outList;
    }

    // Путь Ink, где сейчас стоит история («evening.0.12»), или "" в конце истории.
    public string CurrentPath()
    {
        var story = (Ink.Runtime.Story)RuntimeField.GetValue(this)!;
        return story.state.currentPathString ?? "";
    }
}
