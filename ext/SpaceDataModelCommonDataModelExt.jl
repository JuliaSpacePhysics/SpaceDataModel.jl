module SpaceDataModelCommonDataModelExt

import SpaceDataModel
import SpaceDataModel: name, getmeta
import CommonDataModel as CDM
using CommonDataModel: AbstractVariable, Attributes

SpaceDataModel.name(x::AbstractVariable) = CDM.name(x)

SpaceDataModel.getmeta(x::AbstractVariable, key, default=nothing) = get(Attributes(x), key, default)
SpaceDataModel.getmeta(x::AbstractVariable) = Attributes(x)


end