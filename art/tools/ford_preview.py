"""Сборка пробной сцены брода 8×8 из тайлов art/prologue/tiles/ford (превью для проверки стыков и масштаба).

    python3 art/tools/ford_preview.py [r64]
"""
import sys
from PIL import Image
from pathlib import Path
T=Path(__file__).resolve().parents[1]/'prologue/tiles/ford'/(sys.argv[1] if len(sys.argv)>1 else '')
A=Path(__file__).resolve().parents[1]; C=A/'prologue/characters'
SP=A/'prologue/previews'
N=8
# карта: g трава, s мелко, d глубоко, b берег
M=["ggggbsdb","gggbssdb","ggbssdbg","gbssdbgg","bssdbggg","ssdbgggg","sdbggggg","dbgggggg"]
key={'g':'floor_grass','s':'water_shallow','d':'water_deep','b':'bank_mud'}
objs={(1,1):'campfire',(5,0):'willow',(2,6):'bushes',(0,4):'boulder',(6,3):'fallen_tree',(7,5):'bushes'}
chars={(2,2):C/'hero_fighter_m/base/Idle/rotations/south-east.png',(3,1):C/'hero_cleric_f/base/Idle/rotations/south-east.png',
       (5,6):A/'wave1/characters/overseer/rotations/north-west.png' if (A/'wave1/characters/overseer/rotations/north-west.png').exists() else None}
W,H=N*64+64, N*32+160
S=Image.new('RGBA',(W,H),(24,22,30,255))
ox,oy=W//2-32,90
def pos(x,y): return ox+(x-y)*32, oy+(x+y)*16
for s in range(2*N):
  for x in range(N):
    y=s-x
    if 0<=y<N:
      px,py=pos(x,y); S.alpha_composite(Image.open(T/f'{key[M[y][x]]}.png').convert('RGBA'),(px,py-22))
for s in range(2*N):
  for x in range(N):
    y=s-x
    if not (0<=y<N): continue
    px,py=pos(x,y)
    for d,flip in ((objs,False),(chars,False)):
      if (x,y) in d and d[(x,y)]:
        f=d[(x,y)]; im=Image.open(T/f'{f}.png' if isinstance(f,str) else f).convert('RGBA')
        bb=im.getbbox(); S.alpha_composite(im,(px+32-im.width//2, py+18-bb[3]+ (0 if isinstance(f,str) else 2)))
S=S.resize((S.width*2,S.height*2),Image.NEAREST); S.save(SP/f'ford_scene{"_"+sys.argv[1] if len(sys.argv)>1 else ""}.png'); print(S.size)
