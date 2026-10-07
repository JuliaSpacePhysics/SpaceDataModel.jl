module SpaceDataModelCommonDataModelExt

import SpaceDataModel
import CommonDataModel as CDM
using CommonDataModel: AbstractVariable, Attributes

SpaceDataModel.name(x::AbstractVariable) = CDM.name(x)

SpaceDataModel.getmeta(x::AbstractVariable) = Attributes(x)


end